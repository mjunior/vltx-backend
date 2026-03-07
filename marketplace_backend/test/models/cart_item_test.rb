require "test_helper"

class CartItemTest < ActiveSupport::TestCase
  def create_user(email: "cart-item-model@example.com")
    Users::Create.call(
      email: email,
      password: "password123",
      password_confirmation: "password123"
    ).user
  end

  def create_product_for(user, attrs = {})
    defaults = {
      title: "Produto Item",
      description: "Descricao valida para item de carrinho",
      price: "100.00",
      stock_quantity: 10,
    }

    Products::Create.call(user: user, params: defaults.merge(attrs)).product
  end

  test "requires positive integer quantity" do
    buyer = create_user
    seller = create_user(email: "cart-item-model-seller@example.com")
    cart = Cart.create!(user: buyer, status: :active)
    product = create_product_for(seller)

    cart_item = CartItem.new(cart: cart, product: product, quantity: 0)

    assert_not cart_item.valid?
    assert_includes cart_item.errors[:quantity], "must be greater than 0"
  end

  test "enforces unique product per cart" do
    buyer = create_user(email: "cart-item-model-buyer-uniq@example.com")
    seller = create_user(email: "cart-item-model-seller-uniq@example.com")
    cart = Cart.create!(user: buyer, status: :active)
    product = create_product_for(seller, title: "Unico")

    CartItem.create!(cart: cart, product: product, quantity: 1)

    duplicate = CartItem.new(cart: cart, product: product, quantity: 2)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:product_id], "has already been taken"
  end
end
