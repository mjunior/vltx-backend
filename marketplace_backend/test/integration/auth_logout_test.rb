require "test_helper"

class AuthLogoutTest < ActionDispatch::IntegrationTest
  def login_and_get_tokens(email: "logout@example.com", password: "password123")
    Users::Create.call(
      email: email,
      password: password,
      password_confirmation: password
    )

    post "/auth/login", params: { email: email, password: password }, as: :json
    JSON.parse(response.body).fetch("data")
  end

  test "logout revokes all sessions and returns 204" do
    tokens = login_and_get_tokens
    access_token = tokens.fetch("access_token")

    post "/auth/logout", headers: {
      "Authorization" => "Bearer #{access_token}",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    assert_response :no_content

    user = User.find(tokens.fetch("id"))
    assert_equal 0, user.refresh_sessions.active.count
  end

  test "logout is idempotent for valid token context" do
    tokens = login_and_get_tokens
    access_token = tokens.fetch("access_token")

    post "/auth/logout", headers: {
      "Authorization" => "Bearer #{access_token}",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    assert_response :no_content

    post "/auth/logout", headers: {
      "Authorization" => "Bearer #{access_token}",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    assert_response :no_content
  end

  test "logout returns token invalido when bearer token is malformed" do
    post "/auth/logout", headers: {
      "Authorization" => "Bearer not-a-token",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]
  end

  test "logout requires json content type" do
    post "/auth/logout", headers: {
      "Authorization" => "Bearer something"
    }

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
  end
end
