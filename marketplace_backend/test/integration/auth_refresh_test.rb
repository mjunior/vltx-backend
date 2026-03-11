require "test_helper"

class AuthRefreshTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers
  THROTTLE_IP = "198.51.100.11".freeze

  def create_user(email: "refresh-flow@example.com", password: "password123")
    Users::Create.call(
      email: email,
      password: password,
      password_confirmation: password
    ).user
  end

  def login_and_get_refresh_token(user)
    post "/auth/login", params: {
      email: user.email,
      password: "password123"
    }, as: :json

    JSON.parse(response.body).dig("data", "refresh_token")
  end

  test "refresh rotates token and invalidates previous token" do
    user = create_user
    first_refresh_token = login_and_get_refresh_token(user)

    post "/auth/refresh", params: { refresh_token: first_refresh_token }, as: :json
    assert_response :success

    body = JSON.parse(response.body)
    second_refresh_token = body.dig("data", "refresh_token")
    assert second_refresh_token.present?
    assert_not_equal first_refresh_token, second_refresh_token

    post "/auth/refresh", params: { refresh_token: first_refresh_token }, as: :json
    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]
  end

  test "refresh rejects payload with unknown fields" do
    user = create_user
    refresh_token = login_and_get_refresh_token(user)

    post "/auth/refresh", params: {
      refresh_token: refresh_token,
      other: "not-allowed"
    }, as: :json

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
  end

  test "refresh rejects missing refresh token" do
    post "/auth/refresh", params: {}, as: :json

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
  end

  test "refresh rejects non-json content type" do
    post "/auth/refresh", params: "refresh_token=abc", headers: {
      "CONTENT_TYPE" => "application/x-www-form-urlencoded"
    }

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
  end

  test "refresh rejects expired token" do
    user = create_user
    expired_refresh = Auth::Jwt::Issuer.issue_refresh(user_id: user.id, now: 8.days.ago)
    Auth::Sessions::CreateSession.call(user: user, refresh_token: expired_refresh)

    post "/auth/refresh", params: { refresh_token: expired_refresh.token }, as: :json

    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]
  end

  test "refresh rejects malformed token string" do
    post "/auth/refresh", params: { refresh_token: "bad-token" }, as: :json

    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]
  end

  test "refresh throttles bursts before controller handling" do
    10.times do
      post "/auth/refresh", params: { refresh_token: "bad-token" }, headers: {
        "REMOTE_ADDR" => THROTTLE_IP
      }, as: :json
    end

    post "/auth/refresh", params: { refresh_token: "bad-token" }, headers: {
      "REMOTE_ADDR" => THROTTLE_IP
    }, as: :json

    assert_response :too_many_requests
    assert_equal "muitas requisicoes", JSON.parse(response.body)["error"]
  end
end
