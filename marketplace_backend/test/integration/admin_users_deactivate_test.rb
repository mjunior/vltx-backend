require "test_helper"

class AdminUsersDeactivateTest < ActionDispatch::IntegrationTest
  def create_user(email: "admin-deactivate-user@example.com", password: "password123")
    Users::Create.call(email: email, password: password, password_confirmation: password).user
  end

  def create_admin(email: "admin-deactivate-admin@example.com", password: "password123")
    Admin.create!(email: email, password: password, password_confirmation: password)
  end

  def admin_access_token(admin)
    post "/admin/auth/login", params: { email: admin.email, password: "password123" }, as: :json
    JSON.parse(response.body).dig("data", "access_token")
  end

  def user_login_tokens(user)
    post "/auth/login", params: { email: user.email, password: "password123" }, as: :json
    JSON.parse(response.body).fetch("data")
  end

  test "admin deactivates user and revokes sessions immediately" do
    user = create_user
    login_data = user_login_tokens(user)
    admin = create_admin
    admin_token = admin_access_token(admin)

    patch "/admin/users/#{user.id}/deactivate", headers: {
      "Authorization" => "Bearer #{admin_token}",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal user.id, body.dig("data", "id")
    assert_equal false, body.dig("data", "active")

    user.reload
    assert_equal false, user.active
    assert_equal 0, user.refresh_sessions.active.count

    get "/orders", headers: { "Authorization" => "Bearer #{login_data.fetch('access_token')}" }, as: :json
    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]
  end

  test "deactivated user cannot login again" do
    user = create_user(email: "deactivated-login-user@example.com")
    admin = create_admin(email: "deactivated-login-admin@example.com")
    admin_token = admin_access_token(admin)

    patch "/admin/users/#{user.id}/deactivate", headers: {
      "Authorization" => "Bearer #{admin_token}",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    post "/auth/login", params: { email: user.email, password: "password123" }, as: :json

    assert_response :unauthorized
    assert_equal "credenciais invalidas", JSON.parse(response.body)["error"]
  end

  test "returns not found for missing user" do
    admin = create_admin(email: "missing-user-deactivate-admin@example.com")
    admin_token = admin_access_token(admin)

    patch "/admin/users/#{SecureRandom.uuid}/deactivate", headers: {
      "Authorization" => "Bearer #{admin_token}",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    assert_response :not_found
    assert_equal "nao encontrado", JSON.parse(response.body)["error"]
  end
end
