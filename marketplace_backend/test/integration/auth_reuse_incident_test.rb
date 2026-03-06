require "test_helper"

class AuthReuseIncidentTest < ActionDispatch::IntegrationTest
  def create_user(email: "incident@example.com", password: "password123")
    Users::Create.call(
      email: email,
      password: password,
      password_confirmation: password
    ).user
  end

  def login_tokens(user, password: "password123")
    post "/auth/login", params: {
      email: user.email,
      password: password
    }, as: :json

    JSON.parse(response.body).fetch("data")
  end

  test "reusing previous refresh token triggers global revoke and blocks current refresh" do
    user = create_user
    login_data = login_tokens(user)
    refresh_token_1 = login_data.fetch("refresh_token")

    post "/auth/refresh", params: { refresh_token: refresh_token_1 }, as: :json
    assert_response :success
    refresh_token_2 = JSON.parse(response.body).dig("data", "refresh_token")

    post "/auth/refresh", params: { refresh_token: refresh_token_1 }, as: :json
    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]

    post "/auth/refresh", params: { refresh_token: refresh_token_2 }, as: :json
    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]

    new_login = login_tokens(user)
    assert new_login.fetch("refresh_token").present?
  end
end
