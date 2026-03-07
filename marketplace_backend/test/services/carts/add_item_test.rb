require "test_helper"

module Carts
  class AddItemTest < ActiveSupport::TestCase
    def create_user(email: "cart-add-service@example.com")
      Users::Create.call(
        email: email,
        password: "password123",
        password_confirmation: "password123"
      ).user
    end

    def create_product_for(user, attrs = {})
      defaults = {
        title: "Produto Add",
        description: "Descricao valida para operacao de add item",
        price: "150.50",
        stock_quantity: 7,
      }

      Products::Create.call(user: user, params: defaults.merge(attrs)).product
    end

    test "adds item to active cart and ignores frontend price" do
      buyer = create_user
      seller = create_user(email: "cart-add-seller@example.com")
      product = create_product_for(seller)

      result = AddItem.call(user: buyer, params: {
        product_id: product.id,
        quantity: 2,
        price: "1.00",
      })

      assert result.success?
      cart = result.cart
      assert_equal 1, cart.cart_items.count
      item = cart.cart_items.first
      assert_equal product.id, item.product_id
      assert_equal 2, item.quantity
      assert_equal "301.0", (item.product.price * item.quantity).to_s
    end

    test "clamps quantity to available stock" do
      buyer = create_user(email: "cart-add-clamp-buyer@example.com")
      seller = create_user(email: "cart-add-clamp-seller@example.com")
      product = create_product_for(seller, stock_quantity: 3)

      result = AddItem.call(user: buyer, params: { product_id: product.id, quantity: 10 })

      assert result.success?
      assert_equal 3, result.cart.cart_items.first.quantity
    end

    test "rejects own product" do
      user = create_user(email: "cart-add-own@example.com")
      product = create_product_for(user)

      result = AddItem.call(user: user, params: { product_id: product.id, quantity: 1 })

      assert_not result.success?
      assert_equal :invalid_payload, result.error_code
    end
  end
end
