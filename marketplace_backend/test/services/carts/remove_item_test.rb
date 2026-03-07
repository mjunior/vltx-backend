require "test_helper"

module Carts
  class RemoveItemTest < ActiveSupport::TestCase
    setup do
      InactiveCartAbuseGuard.reset!
    end

    def create_user(email: "cart-remove-service@example.com")
      Users::Create.call(
        email: email,
        password: "password123",
        password_confirmation: "password123"
      ).user
    end

    def create_product_for(user)
      Products::Create.call(user: user, params: {
        title: "Produto Remove",
        description: "Descricao valida para operacao de remove item",
        price: "99.90",
        stock_quantity: 8,
      }).product
    end

    test "removes item from own active cart" do
      buyer = create_user
      seller = create_user(email: "cart-remove-seller@example.com")
      product = create_product_for(seller)
      cart = Cart.create!(user: buyer, status: :active)
      item = CartItem.create!(cart: cart, product: product, quantity: 2)

      result = RemoveItem.call(user: buyer, cart_item_id: item.id)

      assert result.success?
      assert_nil CartItem.find_by(id: item.id)
    end

    test "returns not_found when deleting item from another user cart" do
      owner = create_user(email: "cart-remove-owner@example.com")
      intruder = create_user(email: "cart-remove-intruder@example.com")
      seller = create_user(email: "cart-remove-third-seller@example.com")
      product = create_product_for(seller)
      cart = Cart.create!(user: owner, status: :active)
      item = CartItem.create!(cart: cart, product: product, quantity: 1)

      result = RemoveItem.call(user: intruder, cart_item_id: item.id)

      assert_not result.success?
      assert_equal :not_found, result.error_code
    end

    test "returns invalid_payload for item from own abandoned cart when user has active cart" do
      user = create_user(email: "cart-remove-abandoned-owner@example.com")
      seller = create_user(email: "cart-remove-abandoned-seller@example.com")
      product = create_product_for(seller)
      Cart.create!(user: user, status: :active)
      abandoned_cart = Cart.create!(user: user, status: :abandoned)
      abandoned_item = CartItem.create!(cart: abandoned_cart, product: product, quantity: 1)

      result = RemoveItem.call(user: user, cart_item_id: abandoned_item.id)

      assert_not result.success?
      assert_equal :invalid_payload, result.error_code
    end

    test "returns not_found when user has no active cart even if item exists in inactive cart" do
      user = create_user(email: "cart-remove-no-active@example.com")
      seller = create_user(email: "cart-remove-no-active-seller@example.com")
      product = create_product_for(seller)
      finished_cart = Cart.create!(user: user, status: :finished)
      finished_item = CartItem.create!(cart: finished_cart, product: product, quantity: 1)

      result = RemoveItem.call(user: user, cart_item_id: finished_item.id)

      assert_not result.success?
      assert_equal :not_found, result.error_code
    end
  end
end
