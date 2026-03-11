require "test_helper"

class CartItemsDestroyTest < ActionDispatch::IntegrationTest
  THROTTLE_IP = "198.51.100.23".freeze

  def create_user(email: "cart-items-destroy@example.com", password: "password123")
    Users::Create.call(email: email, password: password, password_confirmation: password).user
  end

  def create_product_for(user)
    Products::Create.call(user: user, params: {
      title: "Produto Cart Destroy",
      description: "Descricao valida para destroy item",
      price: "45.00",
      stock_quantity: 6,
    }).product
  end

  def access_token_for(user, password: "password123")
    post "/auth/login", params: { email: user.email, password: password }, as: :json
    JSON.parse(response.body).dig("data", "access_token")
  end

  test "removes item from authenticated user active cart" do
    buyer = create_user
    seller = create_user(email: "cart-items-destroy-seller@example.com")
    product = create_product_for(seller)
    cart = Cart.create!(user: buyer, status: :active)
    item = CartItem.create!(cart: cart, product: product, quantity: 2)
    token = access_token_for(buyer)

    delete "/cart/items/#{item.id}", headers: {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE" => "application/json",
    }, as: :json

    assert_response :success
    assert_nil CartItem.find_by(id: item.id)
  end

  test "returns 404 when deleting item from another tenant" do
    owner = create_user(email: "cart-items-destroy-owner@example.com")
    intruder = create_user(email: "cart-items-destroy-intruder@example.com")
    seller = create_user(email: "cart-items-destroy-third-seller@example.com")
    product = create_product_for(seller)
    item = CartItem.create!(cart: Cart.create!(user: owner, status: :active), product: product, quantity: 1)
    token = access_token_for(intruder)

    delete "/cart/items/#{item.id}", headers: {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE" => "application/json",
    }, as: :json

    assert_response :not_found
    assert_equal "nao encontrado", JSON.parse(response.body)["error"]
  end

  test "destroy throttles bursts by authenticated actor" do
    buyer = create_user(email: "cart-items-destroy-throttle@example.com")
    seller = create_user(email: "cart-items-destroy-throttle-seller@example.com")
    product = create_product_for(seller)
    cart = Cart.create!(user: buyer, status: :active)
    item = CartItem.create!(cart: cart, product: product, quantity: 2)
    token = access_token_for(buyer)

    20.times do
      delete "/cart/items/#{item.id}", headers: {
        "Authorization" => "Bearer #{token}",
        "CONTENT_TYPE" => "application/json",
        "REMOTE_ADDR" => THROTTLE_IP,
      }, as: :json
    end

    delete "/cart/items/#{item.id}", headers: {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE" => "application/json",
      "REMOTE_ADDR" => THROTTLE_IP,
    }, as: :json

    assert_response :too_many_requests
    assert_equal "muitas requisicoes", JSON.parse(response.body)["error"]
  end
end
