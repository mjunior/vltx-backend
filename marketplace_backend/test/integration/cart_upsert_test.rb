require "test_helper"

class CartUpsertTest < ActionDispatch::IntegrationTest
  def create_user(email: "cart-upsert@example.com", password: "password123")
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

  test "creates active cart for authenticated user with stable contract" do
    user = create_user
    token = access_token_for(user)

    post "/cart", params: {}, headers: {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE" => "application/json",
    }, as: :json

    assert_response :success

    body = JSON.parse(response.body)
    cart_data = body.dig("data", "cart")
    assert cart_data["id"].present?
    assert_equal 0, cart_data["total_items"]
    assert_equal "0.00", cart_data["subtotal"]
    assert_nil cart_data["status"]
    assert_nil cart_data["user_id"]

    persisted = Cart.find(cart_data["id"])
    assert_equal user.id, persisted.user_id
    assert_equal "active", persisted.status
  end

  test "returns same active cart on repeated requests" do
    user = create_user(email: "cart-idempotent@example.com")
    token = access_token_for(user)

    post "/cart", params: {}, headers: {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE" => "application/json",
    }, as: :json
    first_id = JSON.parse(response.body).dig("data", "cart", "id")

    post "/cart", params: {}, headers: {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE" => "application/json",
    }, as: :json
    second_id = JSON.parse(response.body).dig("data", "cart", "id")

    assert_response :success
    assert_equal first_id, second_id
    assert_equal 1, user.carts.active.count
  end

  test "returns token invalido without authorization" do
    post "/cart", params: {}, as: :json

    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]
  end

  test "returns token invalido for malformed bearer token" do
    post "/cart", params: {}, headers: {
      "Authorization" => "Bearer invalid-token",
      "CONTENT_TYPE" => "application/json",
    }, as: :json

    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]
  end

  test "returns payload invalido for forbidden targeting keys in payload" do
    user = create_user(email: "cart-forbidden-payload@example.com")
    token = access_token_for(user)
    target = create_user(email: "cart-forbidden-target@example.com")

    post "/cart", params: {
      cart: {
        user_id: target.id,
      },
    }, headers: {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE" => "application/json",
    }, as: :json

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
  end
end
