require "test_helper"

class AdminUserVerificationStatusTest < ActionDispatch::IntegrationTest
  def create_user(email: "verification-user@example.com", password: "password123")
    Users::Create.call(
      email: email,
      password: password,
      password_confirmation: password
    ).user
  end

  def create_admin(email: "verification-admin@example.com", password: "password123")
    Admin.create!(email: email, password: password, password_confirmation: password)
  end

  def admin_access_token(admin)
    post "/admin/auth/login", params: { email: admin.email, password: "password123" }, as: :json
    JSON.parse(response.body).dig("data", "access_token")
  end

  test "admin can read user verification status" do
    user = create_user
    user.update!(verification_status: :verified)
    admin = create_admin
    access_token = admin_access_token(admin)

    get "/admin/users/#{user.id}/verification-status", headers: {
      "Authorization" => "Bearer #{access_token}"
    }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    data = body.fetch("data")

    assert_equal user.id, data.fetch("id")
    assert_equal user.email, data.fetch("email")
    assert_equal "verified", data.fetch("verification_status")
  end

  test "verification status is not exposed in regular user login contract" do
    user = create_user(email: "login-contract-user@example.com")

    post "/auth/login", params: { email: user.email, password: "password123" }, as: :json

    assert_response :success
    data = JSON.parse(response.body).fetch("data")
    assert_not data.key?("verification_status")
  end

  test "returns not found for missing user id" do
    admin = create_admin(email: "missing-user-admin@example.com")
    access_token = admin_access_token(admin)

    get "/admin/users/999999/verification-status", headers: {
      "Authorization" => "Bearer #{access_token}"
    }, as: :json

    assert_response :not_found
    assert_equal "nao encontrado", JSON.parse(response.body)["error"]
  end
end
