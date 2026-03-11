require "test_helper"

class AdminAuthRefreshTest < ActionDispatch::IntegrationTest
  THROTTLE_IP = "198.51.100.13".freeze

  def create_admin(email: "admin-refresh@example.com", password: "password123", active: true)
    Admin.create!(email: email, password: password, password_confirmation: password, active: active)
  end

  def login_admin(admin, password: "password123")
    post "/admin/auth/login", params: {
      email: admin.email,
      password: password
    }, as: :json

    JSON.parse(response.body).fetch("data")
  end

  test "refresh rotates admin session and returns new token pair" do
    admin = create_admin
    login_data = login_admin(admin)
    old_refresh = login_data.fetch("refresh_token")
    old_session = admin.admin_refresh_sessions.first

    post "/admin/auth/refresh", params: { refresh_token: old_refresh }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    data = body.fetch("data")

    assert data.fetch("access_token").present?
    assert data.fetch("refresh_token").present?
    assert_not_equal old_refresh, data.fetch("refresh_token")

    old_session.reload
    assert old_session.rotated_at.present?
  end

  test "refresh rejects user refresh token in admin namespace" do
    user = Users::Create.call(
      email: "user-refresh@example.com",
      password: "password123",
      password_confirmation: "password123"
    ).user
    user_refresh = Auth::Jwt::Issuer.issue_refresh(user_id: user.id)
    Auth::Sessions::CreateSession.call(user: user, refresh_token: user_refresh)

    post "/admin/auth/refresh", params: { refresh_token: user_refresh.token }, as: :json

    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]
  end

  test "refresh rejects token when admin becomes inactive" do
    admin = create_admin(email: "inactive-after-login@example.com")
    login_data = login_admin(admin)
    admin.update!(active: false)

    post "/admin/auth/refresh", params: { refresh_token: login_data.fetch("refresh_token") }, as: :json

    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]
  end

  test "admin refresh throttles bursts before token rotation" do
    5.times do
      post "/admin/auth/refresh", params: { refresh_token: "bad-token" }, headers: {
        "REMOTE_ADDR" => THROTTLE_IP
      }, as: :json
    end

    post "/admin/auth/refresh", params: { refresh_token: "bad-token" }, headers: {
      "REMOTE_ADDR" => THROTTLE_IP
    }, as: :json

    assert_response :too_many_requests
    assert_equal "muitas requisicoes", JSON.parse(response.body)["error"]
  end
end
