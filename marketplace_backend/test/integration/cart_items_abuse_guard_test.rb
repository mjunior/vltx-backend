require "test_helper"

class CartItemsAbuseGuardTest < ActionDispatch::IntegrationTest
  setup do
    Carts::InactiveCartAbuseGuard.reset!
  end

  def create_user(email: "cart-abuse-guard@example.com", password: "password123")
    Users::Create.call(email: email, password: password, password_confirmation: password).user
  end

  def create_product_for(user, attrs = {})
    Products::Create.call(user: user, params: {
      title: "Produto Abuse Guard",
      description: "Descricao valida para testes de abuso em carrinho inativo",
      price: "110.00",
      stock_quantity: 5,
    }.merge(attrs)).product
  end

  def login_tokens_for(user, password: "password123")
    post "/auth/login", params: { email: user.email, password: password }, as: :json
    body = JSON.parse(response.body)
    {
      access_token: body.dig("data", "access_token"),
      refresh_token: body.dig("data", "refresh_token"),
    }
  end

  test "revokes refresh sessions after repeated inactive cart mutation attempts" do
    buyer = create_user
    seller = create_user(email: "cart-abuse-guard-seller@example.com")
    product = create_product_for(seller)
    Cart.create!(user: buyer, status: :active)
    finished_item = CartItem.create!(cart: Cart.create!(user: buyer, status: :finished), product: product, quantity: 1)
    tokens = login_tokens_for(buyer)

    3.times do
      patch "/cart/items/#{finished_item.id}", params: {
        cart_item: { quantity: 2 },
      }, headers: {
        "Authorization" => "Bearer #{tokens[:access_token]}",
        "CONTENT_TYPE" => "application/json",
      }, as: :json

      assert_response :unprocessable_entity
      assert_equal "payload invalido", JSON.parse(response.body)["error"]
    end

    post "/auth/refresh", params: { refresh_token: tokens[:refresh_token] }, as: :json

    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]
  end
end
