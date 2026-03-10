require "test_helper"

class AdminAuthLogoutTest < ActionDispatch::IntegrationTest
  def create_admin(email: "admin-logout@example.com", password: "password123")
    Admin.create!(email: email, password: password, password_confirmation: password)
  end

  def login_admin(admin)
    post "/admin/auth/login", params: {
      email: admin.email,
      password: "password123"
    }, as: :json

    JSON.parse(response.body).fetch("data")
  end

  test "logout revokes all admin refresh sessions" do
    admin = create_admin
    login_data = login_admin(admin)
    second_refresh = AdminAuth::Jwt::Issuer.issue_refresh(admin_id: admin.id)
    AdminAuth::Sessions::CreateSession.call(admin: admin, refresh_token: second_refresh)

    post "/admin/auth/logout", headers: {
      "Authorization" => "Bearer #{login_data.fetch('access_token')}",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    assert_response :no_content
    assert_equal 0, admin.admin_refresh_sessions.active.count
  end

  test "logout rejects user access token" do
    user = Users::Create.call(
      email: "logout-user@example.com",
      password: "password123",
      password_confirmation: "password123"
    ).user
    user_access = Auth::Jwt::Issuer.issue_access(user_id: user.id).token

    post "/admin/auth/logout", headers: {
      "Authorization" => "Bearer #{user_access}",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]
  end
end
