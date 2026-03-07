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

    test "finalizes active cart with wallet and returns preparation payload" do
      buyer = create_user
      seller = create_user(email: "cart-finalize-service-seller@example.com")
      product = create_product_for(seller)
      cart = Cart.create!(user: buyer, status: :active)
      CartItem.create!(cart: cart, product: product, quantity: 2)

      result = Finalize.call(user: buyer, params: { payment_method: "wallet" })

      assert result.success?
      assert_equal "finished", result.cart.status
      assert_equal cart.id, result.preparation[:source_cart_id]
      assert_equal "wallet", result.preparation[:payment_method]
      assert_equal 2, result.preparation[:total_items]
      assert_equal "240.00", result.preparation[:subtotal]
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
  end
end
