require "test_helper"

module Orders
  class MarkDeliveredTest < ActiveSupport::TestCase
    def create_user(email: "orders-deliver-buyer@example.com")
      Users::Create.call(
        email: email,
        password: "password123",
        password_confirmation: "password123"
      ).user
    end

    def create_product_for(user, attrs = {})
      defaults = {
        title: "Produto Deliver",
        description: "Descricao valida para entrega",
        price: "60.00",
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
    end

    def create_confirmed_order
      buyer = create_user
      seller = create_user(email: "orders-deliver-seller@example.com")
      product = create_product_for(seller, stock_quantity: 3)
      cart = Cart.create!(user: buyer, status: :active)
      CartItem.create!(cart: cart, product: product, quantity: 1)
      seed_wallet_for(buyer, amount_cents: 200_00)
      result = Carts::Finalize.call(user: buyer, params: { payment_method: "wallet" })
      raise "checkout failed" unless result.success?
      order = Order.find(result.order_ids.first)
      Orders::Advance.call(order: order, actor: order.seller)
      Orders::Advance.call(order: order.reload, actor: order.seller)
      order.reload
    end

    test "marks confirmed order as delivered and credits seller wallet" do
      order = create_confirmed_order
      seller_wallet = Wallet.find_or_create_by!(user: order.seller)

      result = MarkDelivered.call(order: order, actor: order.user)

      assert result.success?
      assert_equal "delivered", result.order.reload.status
      assert_equal "credited", result.order.seller_receivable.reload.status
      assert_equal order.subtotal_cents, seller_wallet.reload.current_balance_cents
      assert_equal 1, seller_wallet.wallet_transactions.where(transaction_type: :credit, reference_id: order.id).count
    end

    test "rejects delivery before confirmed" do
      buyer = create_user(email: "orders-deliver-early-buyer@example.com")
      seller = create_user(email: "orders-deliver-early-seller@example.com")
      product = create_product_for(seller, stock_quantity: 3)
      cart = Cart.create!(user: buyer, status: :active)
      CartItem.create!(cart: cart, product: product, quantity: 1)
      seed_wallet_for(buyer, amount_cents: 200_00)
      result = Carts::Finalize.call(user: buyer, params: { payment_method: "wallet" })
      order = Order.find(result.order_ids.first)

      delivery = MarkDelivered.call(order: order, actor: order.user)

      assert_not delivery.success?
      assert_equal :invalid_transition, delivery.error_code
    end
  end
end
