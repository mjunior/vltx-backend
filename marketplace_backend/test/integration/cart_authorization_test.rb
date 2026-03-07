require "test_helper"

class CartAuthorizationTest < ActionDispatch::IntegrationTest
  def create_user(email: "cart-authz@example.com", password: "password123")
    Users::Create.call(
      email: email,
      password: password,
      password_confirmation: password
    ).user
  end

  def access_token_for(user, password: "password123")
    post "/auth/login", params: {
      email: user.email,
      password: password,
    }, as: :json

    JSON.parse(response.body).dig("data", "access_token")
  end

  test "rejects forged user targeting in query params" do
    user = create_user
    target = create_user(email: "cart-authz-target@example.com")
    token = access_token_for(user)

    post "/cart", params: { user_id: target.id }, headers: {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE" => "application/json",
    }, as: :json

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
    assert_equal 0, target.carts.count
  end

  test "rejects nested forged keys and does not leak target tenant" do
    user = create_user(email: "cart-authz-owner@example.com")
    target = create_user(email: "cart-authz-intruder@example.com")
    token = access_token_for(user)

    post "/cart", params: {
      cart: {
        owner_id: target.id,
      },
    }, headers: {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE" => "application/json",
    }, as: :json

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
    assert_equal 0, target.carts.count
    assert_equal 0, user.carts.count
  end
end
