require "test_helper"

module Orders
  class CancelTest < ActiveSupport::TestCase
    def create_user(email: "orders-cancel-buyer@example.com")
      Users::Create.call(
        email: email,
        password: "password123",
        password_confirmation: "password123"
      ).user
    end

    def create_product_for(user, attrs = {})
      defaults = {
        title: "Produto Cancel",
        description: "Descricao valida para cancelamento",
        price: "40.00",
        stock_quantity: 10
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

      wallet.reload
    end

    def create_paid_order
      buyer = create_user
      seller = create_user(email: "orders-cancel-seller@example.com")
      product = create_product_for(seller, stock_quantity: 5)
      cart = Cart.create!(user: buyer, status: :active)
      CartItem.create!(cart: cart, product: product, quantity: 2)
      seed_wallet_for(buyer, amount_cents: 500_00)
      result = Carts::Finalize.call(user: buyer, params: { payment_method: "wallet" })
      raise "checkout failed" unless result.success?

      Order.find(result.order_ids.first)
    end

    test "cancels paid order with refund, stock restore and receivable reversal" do
      order = create_paid_order
      buyer_wallet = Wallet.find_by!(user_id: order.user_id)

      result = Cancel.call(order: order, actor: order.user)

      assert result.success?
      assert_equal "canceled", result.order.reload.status
      assert_equal 500_00, buyer_wallet.reload.current_balance_cents
      assert_equal 5, order.order_items.first.product.reload.stock_quantity
      assert_equal "reversed", order.seller_receivable.reload.status
      assert_equal 1, buyer_wallet.wallet_transactions.where(transaction_type: :refund, reference_id: order.id).count
    end

    test "rejects cancellation once order left paid state" do
      order = create_paid_order
      Orders::Advance.call(order: order, actor: order.seller)

      result = Cancel.call(order: order.reload, actor: order.user)

      assert_not result.success?
      assert_equal :invalid_transition, result.error_code
    end
  end
end
