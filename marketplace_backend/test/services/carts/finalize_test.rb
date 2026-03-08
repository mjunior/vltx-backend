require "test_helper"

module Carts
  class FinalizeTest < ActiveSupport::TestCase
    def create_user(email: "cart-finalize-service@example.com")
      Users::Create.call(
        email: email,
        password: "password123",
        password_confirmation: "password123"
      ).user
    end

    def create_product_for(user, attrs = {})
      defaults = {
        title: "Produto Finalize",
        description: "Descricao valida para operacao de finalize checkout",
        price: "120.00",
        stock_quantity: 5,
      }

      Products::Create.call(user: user, params: defaults.merge(attrs)).product
    end

    def create_wallet_for(user, balance_cents:)
      wallet = Wallet.create!(user: user, current_balance_cents: 0)
      return wallet if balance_cents.zero?

      seed = Wallets::Ledger::AppendTransaction.call(
        wallet: wallet,
        transaction_type: :credit,
        amount_cents: balance_cents,
        reference_type: "seed",
        reference_id: "seed-#{user.id}",
        operation_key: "seed-wallet-#{user.id}",
        metadata: { "source" => "test_seed" }
      )
      raise "wallet seed failed" unless seed.success?

      wallet.reload
    end

    test "finalizes active cart with wallet and returns preparation payload" do
      buyer = create_user
      seller = create_user(email: "cart-finalize-service-seller@example.com")
      product = create_product_for(seller)
      cart = Cart.create!(user: buyer, status: :active)
      CartItem.create!(cart: cart, product: product, quantity: 2)
      wallet = create_wallet_for(buyer, balance_cents: 500_00)

      result = Finalize.call(user: buyer, params: { payment_method: "wallet" })

      assert result.success?
      assert_equal "finished", result.cart.status
      assert_equal cart.id, result.preparation[:source_cart_id]
      assert_equal "wallet", result.preparation[:payment_method]
      assert_equal 2, result.preparation[:total_items]
      assert_equal "240.00", result.preparation[:subtotal]
      assert_equal 260_00, wallet.reload.current_balance_cents
      assert_equal 2, wallet.wallet_transactions.count
    end

    test "returns invalid_payload for non-wallet method" do
      buyer = create_user(email: "cart-finalize-service-wallet@example.com")

      result = Finalize.call(user: buyer, params: { payment_method: "pix" })

      assert_not result.success?
      assert_equal :invalid_payload, result.error_code
    end

    test "returns not_found when user has no active cart" do
      buyer = create_user(email: "cart-finalize-service-no-active@example.com")
      Cart.create!(user: buyer, status: :finished)

      result = Finalize.call(user: buyer, params: { payment_method: "wallet" })

      assert_not result.success?
      assert_equal :not_found, result.error_code
    end

    test "returns invalid_payload for empty active cart" do
      buyer = create_user(email: "cart-finalize-service-empty@example.com")
      Cart.create!(user: buyer, status: :active)

      result = Finalize.call(user: buyer, params: { payment_method: "wallet" })

      assert_not result.success?
      assert_equal :invalid_payload, result.error_code
    end

    test "returns insufficient_funds when wallet has insufficient funds" do
      buyer = create_user(email: "cart-finalize-service-no-funds@example.com")
      seller = create_user(email: "cart-finalize-service-no-funds-seller@example.com")
      product = create_product_for(seller, price: "200.00")
      cart = Cart.create!(user: buyer, status: :active)
      CartItem.create!(cart: cart, product: product, quantity: 1)
      wallet = create_wallet_for(buyer, balance_cents: 50_00)

      result = Finalize.call(user: buyer, params: { payment_method: "wallet" })

      assert_not result.success?
      assert_equal :insufficient_funds, result.error_code
      assert_equal "active", cart.reload.status
      assert_equal 50_00, wallet.reload.current_balance_cents
      assert_equal 1, wallet.wallet_transactions.count
    end
  end
end
