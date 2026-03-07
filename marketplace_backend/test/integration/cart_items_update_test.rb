require "test_helper"

class CartItemsUpdateTest < ActionDispatch::IntegrationTest
  def create_user(email: "cart-items-update@example.com", password: "password123")
    Users::Create.call(email: email, password: password, password_confirmation: password).user
  end

  def create_product_for(user, attrs = {})
    Products::Create.call(user: user, params: {
      title: "Produto Cart Update",
      description: "Descricao valida para update item",
      price: "120.00",
      stock_quantity: 5,
    }.merge(attrs)).product
  end

  def access_token_for(user, password: "password123")
    post "/auth/login", params: { email: user.email, password: password }, as: :json
    JSON.parse(response.body).dig("data", "access_token")
  end

  test "updates item quantity and keeps tenant scope" do
    buyer = create_user
    seller = create_user(email: "cart-items-update-seller@example.com")
    product = create_product_for(seller)
    cart = Cart.create!(user: buyer, status: :active)
    item = CartItem.create!(cart: cart, product: product, quantity: 1)
    token = access_token_for(buyer)

    patch "/cart/items/#{item.id}", params: {
      cart_item: {
        quantity: 4,
      },
    }, headers: {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE" => "application/json",
    }, as: :json

    assert_response :success
    assert_equal 4, item.reload.quantity
  end

  test "returns 404 for cart item from another tenant" do
    owner = create_user(email: "cart-items-update-owner@example.com")
    intruder = create_user(email: "cart-items-update-intruder@example.com")
    seller = create_user(email: "cart-items-update-third-seller@example.com")
    product = create_product_for(seller)
    item = CartItem.create!(cart: Cart.create!(user: owner, status: :active), product: product, quantity: 2)
    token = access_token_for(intruder)

    patch "/cart/items/#{item.id}", params: {
      cart_item: {
        quantity: 3,
      },
    }, headers: {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE" => "application/json",
    }, as: :json

    assert_response :not_found
    assert_equal "nao encontrado", JSON.parse(response.body)["error"]
  end
end
