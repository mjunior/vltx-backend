require "test_helper"

module Carts
  class UpdateItemTest < ActiveSupport::TestCase
    setup do
      InactiveCartAbuseGuard.reset!
    end

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

    test "returns invalid_payload for item from own finished cart when user has active cart" do
      user = create_user(email: "cart-update-finished-owner@example.com")
      seller = create_user(email: "cart-update-finished-seller@example.com")
      product = create_product_for(seller)
      Cart.create!(user: user, status: :active)
      finished_cart = Cart.create!(user: user, status: :finished)
      finished_item = CartItem.create!(cart: finished_cart, product: product, quantity: 1)

      result = UpdateItem.call(user: user, cart_item_id: finished_item.id, params: { quantity: 2 })

      assert_not result.success?
      assert_equal :invalid_payload, result.error_code
    end

    test "returns not_found when user has no active cart even if item exists in inactive cart" do
      user = create_user(email: "cart-update-no-active@example.com")
      seller = create_user(email: "cart-update-no-active-seller@example.com")
      product = create_product_for(seller)
      finished_cart = Cart.create!(user: user, status: :finished)
      finished_item = CartItem.create!(cart: finished_cart, product: product, quantity: 1)

      result = UpdateItem.call(user: user, cart_item_id: finished_item.id, params: { quantity: 2 })

      assert_not result.success?
      assert_equal :not_found, result.error_code
    end
  end
end
