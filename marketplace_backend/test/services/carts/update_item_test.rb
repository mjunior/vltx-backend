require "test_helper"

module Carts
  class UpdateItemTest < ActiveSupport::TestCase
    def create_user(email: "cart-update-service@example.com")
      Users::Create.call(
        email: email,
        password: "password123",
        password_confirmation: "password123"
      ).user
    end

    def create_product_for(user, attrs = {})
      defaults = {
        title: "Produto Update",
        description: "Descricao valida para operacao de update item",
        price: "20.00",
        stock_quantity: 5,
      }

      Products::Create.call(user: user, params: defaults.merge(attrs)).product
    end

    test "updates quantity in own active cart" do
      buyer = create_user
      seller = create_user(email: "cart-update-seller@example.com")
      product = create_product_for(seller)
      cart = Cart.create!(user: buyer, status: :active)
      item = CartItem.create!(cart: cart, product: product, quantity: 1)

      result = UpdateItem.call(user: buyer, cart_item_id: item.id, params: { quantity: 4 })

      assert result.success?
      assert_equal 4, item.reload.quantity
    end

    test "clamps update quantity to stock" do
      buyer = create_user(email: "cart-update-clamp-buyer@example.com")
      seller = create_user(email: "cart-update-clamp-seller@example.com")
      product = create_product_for(seller, stock_quantity: 2)
      cart = Cart.create!(user: buyer, status: :active)
      item = CartItem.create!(cart: cart, product: product, quantity: 1)

      result = UpdateItem.call(user: buyer, cart_item_id: item.id, params: { quantity: 10 })

      assert result.success?
      assert_equal 2, item.reload.quantity
    end

    test "returns not_found for item outside user active cart" do
      owner = create_user(email: "cart-update-owner@example.com")
      intruder = create_user(email: "cart-update-intruder@example.com")
      seller = create_user(email: "cart-update-third-seller@example.com")
      product = create_product_for(seller)
      owner_cart = Cart.create!(user: owner, status: :active)
      item = CartItem.create!(cart: owner_cart, product: product, quantity: 1)

      result = UpdateItem.call(user: intruder, cart_item_id: item.id, params: { quantity: 2 })

      assert_not result.success?
      assert_equal :not_found, result.error_code
    end
  end
end
