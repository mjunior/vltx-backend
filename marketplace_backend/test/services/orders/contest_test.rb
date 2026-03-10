require "test_helper"

module Orders
  class ContestTest < ActiveSupport::TestCase
    def create_user(email: "orders-contest-buyer@example.com")
      Users::Create.call(
        email: email,
        password: "password123",
        password_confirmation: "password123"
      ).user
    end

    def create_product_for(user, attrs = {})
      defaults = {
        title: "Produto Contest",
        description: "Descricao valida para contestacao",
        price: "60.00",
        stock_quantity: 4
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

    def create_delivered_order
      buyer = create_user
      seller = create_user(email: "orders-contest-seller@example.com")
      product = create_product_for(seller)
      cart = Cart.create!(user: buyer, status: :active)
      CartItem.create!(cart: cart, product: product, quantity: 1)
      seed_wallet_for(buyer, amount_cents: 200_00)
      checkout = Carts::Finalize.call(user: buyer, params: { payment_method: "wallet" })
      raise "checkout failed" unless checkout.success?
      order = Order.find(checkout.order_ids.first)
      Orders::Advance.call(order: order, actor: order.seller)
      Orders::Advance.call(order: order.reload, actor: order.seller)
      Orders::MarkDelivered.call(order: order.reload, actor: order.user)
      order.reload
    end

    test "buyer contests delivered order without wallet reversal" do
      order = create_delivered_order
      buyer_wallet_balance = Wallet.find_by!(user: order.user).current_balance_cents
      seller_wallet_balance = Wallet.find_by!(user: order.seller).current_balance_cents

      result = Contest.call(order: order, actor: order.user)

      assert result.success?
      assert_equal "contested", result.order.reload.status
      assert_equal buyer_wallet_balance, Wallet.find_by!(user: order.user).current_balance_cents
      assert_equal seller_wallet_balance, Wallet.find_by!(user: order.seller).current_balance_cents
      assert_equal "credited", order.seller_receivable.reload.status
    end

    test "rejects contest before delivery" do
      buyer = create_user(email: "orders-contest-early-buyer@example.com")
      seller = create_user(email: "orders-contest-early-seller@example.com")
      product = create_product_for(seller)
      cart = Cart.create!(user: buyer, status: :active)
      CartItem.create!(cart: cart, product: product, quantity: 1)
      seed_wallet_for(buyer, amount_cents: 200_00)
      checkout = Carts::Finalize.call(user: buyer, params: { payment_method: "wallet" })
      order = Order.find(checkout.order_ids.first)

      result = Contest.call(order: order, actor: order.user)

      assert_not result.success?
      assert_equal :invalid_transition, result.error_code
    end
  end
end
