require "test_helper"

module Orders
  class PrepareFromCartTest < ActiveSupport::TestCase
    def create_user(email: "orders-prepare-service@example.com")
      Users::Create.call(
        email: email,
        password: "password123",
        password_confirmation: "password123"
      ).user
    end

    def create_product_for(user, attrs = {})
      defaults = {
        title: "Produto Prepare Order",
        description: "Descricao valida para preparacao de pedido",
        price: "50.00",
        stock_quantity: 8,
      }

      Products::Create.call(user: user, params: defaults.merge(attrs)).product
    end

    test "returns snapshot payload for finished cart" do
      buyer = create_user
      seller = create_user(email: "orders-prepare-service-seller@example.com")
      first = create_product_for(seller, title: "Produto A", price: "50.00")
      second = create_product_for(seller, title: "Produto B", price: "30.00")
      cart = Cart.create!(user: buyer, status: :finished)
      CartItem.create!(cart: cart, product: first, quantity: 2)
      CartItem.create!(cart: cart, product: second, quantity: 1)

      result = PrepareFromCart.call(cart: cart)

      assert result.success?
      payload = result.preparation
      assert_equal cart.id, payload[:source_cart_id]
      assert_equal "wallet", payload[:payment_method]
      assert_equal "BRL", payload[:currency]
      assert_equal 3, payload[:total_items]
      assert_equal "130.00", payload[:subtotal]
      assert_equal 2, payload[:items].length
    end

    test "returns invalid_payload for active cart" do
      user = create_user(email: "orders-prepare-active@example.com")
      cart = Cart.create!(user: user, status: :active)

      result = PrepareFromCart.call(cart: cart)

      assert_not result.success?
      assert_equal :invalid_payload, result.error_code
    end

    test "does not require order persistence in this phase" do
      assert_not ActiveRecord::Base.connection.data_source_exists?("orders")
    end
  end
end
