require "test_helper"

module Orders
  class CancelIdempotencyTest < ActiveSupport::TestCase
    def create_user(email: "orders-cancel-idempotency-buyer@example.com")
      Users::Create.call(
        email: email,
        password: "password123",
        password_confirmation: "password123"
      ).user
    end

    def create_product_for(user, attrs = {})
      defaults = {
        title: "Produto Cancel Retry",
        description: "Descricao valida para idempotencia",
        price: "70.00",
        stock_quantity: 8
      }

      Products::Create.call(user: user, params: defaults.merge(attrs)).product
    end

    def seed_wallet_for(user, amount_cents:)
      wallet = Wallet.find_or_create_by!(user: user)
      result = Wallets::Ledger::AppendTransaction.call(
        wallet: wallet,
        transaction_type: :credit,
        amount_cents: amount_cents,
        reference_type: "seed",
        reference_id: "seed-#{user.id}",
        operation_key: "seed-#{user.id}",
        metadata: { "source" => "seed" }
      )
      raise "seed failed" unless result.success?
    end

    def create_paid_order
      buyer = create_user
      seller = create_user(email: "orders-cancel-idempotency-seller@example.com")
      product = create_product_for(seller, stock_quantity: 4)
      cart = Cart.create!(user: buyer, status: :active)
      CartItem.create!(cart: cart, product: product, quantity: 2)
      seed_wallet_for(buyer, amount_cents: 400_00)
      result = Carts::Finalize.call(user: buyer, params: { payment_method: "wallet" })

      Order.find(result.order_ids.first)
    end

    test "cancel applies refund and stock restore only once on retry" do
      order = create_paid_order
      product = order.order_items.first.product
      wallet = Wallet.find_by!(user_id: order.user_id)

      first = Cancel.call(order: order, actor: order.user)
      second = Cancel.call(order: order.reload, actor: order.user)

      assert first.success?
      assert second.success?
      assert_equal "canceled", order.reload.status
      assert_equal 4, product.reload.stock_quantity
      assert_equal 400_00, wallet.reload.current_balance_cents
      assert_equal 1, wallet.wallet_transactions.where(transaction_type: :refund, reference_id: order.id).count
    end
  end
end
