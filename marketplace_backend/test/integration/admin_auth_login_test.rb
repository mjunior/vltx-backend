require "test_helper"

class AdminAuthLoginTest < ActionDispatch::IntegrationTest
  def create_admin(email: "admin-login@example.com", password: "password123", active: true)
    Admin.create!(email: email, password: password, password_confirmation: password, active: active)
  end

  test "login returns token pair and admin data" do
    admin = create_admin

    post "/admin/auth/login", params: {
      email: admin.email,
      password: "password123"
    }, as: :json

    assert_response :success

    body = JSON.parse(response.body)
    data = body.fetch("data")

    assert_equal admin.id, data.fetch("id")
    assert_equal admin.email, data.fetch("email")
    assert_equal "Bearer", data.fetch("token_type")
    assert data.fetch("access_token").present?
    assert data.fetch("refresh_token").present?
    assert_equal 15.minutes.to_i, data.fetch("access_expires_in")
    assert_equal 7.days.to_i, data.fetch("refresh_expires_in")
    assert_equal 1, admin.admin_refresh_sessions.count
  end

  test "login returns generic invalid credentials for inactive admin" do
    admin = create_admin(email: "inactive-admin@example.com", active: false)

    post "/admin/auth/login", params: {
      email: admin.email,
      password: "password123"
    }, as: :json

    assert_response :unauthorized
    assert_equal "credenciais invalidas", JSON.parse(response.body)["error"]
  end

  test "login returns generic invalid credentials for wrong password" do
    admin = create_admin(email: "wrong-password-admin@example.com")

    post "/admin/auth/login", params: {
      email: admin.email,
      password: "wrong-password"
    }, as: :json

    assert_response :unauthorized
    assert_equal "credenciais invalidas", JSON.parse(response.body)["error"]
  end

  test "login returns payload invalido when params are missing" do
    post "/admin/auth/login", params: {}, as: :json

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
  end
end
