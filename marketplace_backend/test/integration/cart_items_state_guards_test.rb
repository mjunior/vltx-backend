require "test_helper"

class CartItemsStateGuardsTest < ActionDispatch::IntegrationTest
  setup do
    Carts::InactiveCartAbuseGuard.reset!
  end

  def create_user(email: "cart-state-guards@example.com", password: "password123")
    Users::Create.call(email: email, password: password, password_confirmation: password).user
  end

  def create_product_for(user, attrs = {})
    Products::Create.call(user: user, params: {
      title: "Produto State Guard",
      description: "Descricao valida para guardas de estado do carrinho",
      price: "80.00",
      stock_quantity: 5,
    }.merge(attrs)).product
  end

  def access_token_for(user, password: "password123")
    post "/auth/login", params: { email: user.email, password: password }, as: :json
    JSON.parse(response.body).dig("data", "access_token")
  end

  test "returns 422 when updating item from own finished cart while active cart exists" do
    buyer = create_user
    seller = create_user(email: "cart-state-guards-seller-update@example.com")
    product = create_product_for(seller)
    Cart.create!(user: buyer, status: :active)
    finished_item = CartItem.create!(cart: Cart.create!(user: buyer, status: :finished), product: product, quantity: 1)
    token = access_token_for(buyer)

    patch "/cart/items/#{finished_item.id}", params: {
      cart_item: { quantity: 2 },
    }, headers: {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE" => "application/json",
    }, as: :json

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
  end

  test "returns 422 when deleting item from own abandoned cart while active cart exists" do
    buyer = create_user(email: "cart-state-guards-owner-delete@example.com")
    seller = create_user(email: "cart-state-guards-seller-delete@example.com")
    product = create_product_for(seller)
    Cart.create!(user: buyer, status: :active)
    abandoned_item = CartItem.create!(cart: Cart.create!(user: buyer, status: :abandoned), product: product, quantity: 1)
    token = access_token_for(buyer)

    delete "/cart/items/#{abandoned_item.id}", headers: {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE" => "application/json",
    }, as: :json

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
  end

  test "returns 404 for update when no active cart exists" do
    buyer = create_user(email: "cart-state-guards-no-active-update@example.com")
    seller = create_user(email: "cart-state-guards-no-active-update-seller@example.com")
    product = create_product_for(seller)
    item = CartItem.create!(cart: Cart.create!(user: buyer, status: :finished), product: product, quantity: 1)
    token = access_token_for(buyer)

    patch "/cart/items/#{item.id}", params: {
      cart_item: { quantity: 3 },
    }, headers: {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE" => "application/json",
    }, as: :json

    assert_response :not_found
    assert_equal "nao encontrado", JSON.parse(response.body)["error"]
  end

  test "returns 404 for delete when no active cart exists" do
    buyer = create_user(email: "cart-state-guards-no-active-delete@example.com")
    seller = create_user(email: "cart-state-guards-no-active-delete-seller@example.com")
    product = create_product_for(seller)
    item = CartItem.create!(cart: Cart.create!(user: buyer, status: :abandoned), product: product, quantity: 1)
    token = access_token_for(buyer)

    delete "/cart/items/#{item.id}", headers: {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE" => "application/json",
    }, as: :json

    assert_response :not_found
    assert_equal "nao encontrado", JSON.parse(response.body)["error"]
  end
end
