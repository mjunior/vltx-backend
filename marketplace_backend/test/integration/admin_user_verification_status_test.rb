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

  test "admin can list users with active and verification status" do
    user = create_user
    user.update!(verification_status: :verified)
    other_user = create_user(email: "other-verification-user@example.com")
    admin = create_admin
    access_token = admin_access_token(admin)

    get "/admin/users", headers: {
      "Authorization" => "Bearer #{access_token}"
    }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    users = body.dig("data", "users")
    listed_user = users.find { |row| row.fetch("id") == user.id }
    listed_other = users.find { |row| row.fetch("id") == other_user.id }

    assert_equal user.email, listed_user.fetch("email")
    assert_equal true, listed_user.fetch("active")
    assert_equal "verified", listed_user.fetch("verification_status")
    assert_equal "unverified", listed_other.fetch("verification_status")
  end

  test "admin can read user detail with active and verification status" do
    user = create_user(email: "detail-user@example.com")
    user.update!(active: false, verification_status: :verified)
    admin = create_admin(email: "detail-admin@example.com")
    access_token = admin_access_token(admin)

    get "/admin/users/#{user.id}", headers: {
      "Authorization" => "Bearer #{access_token}"
    }, as: :json

    assert_response :success
    data = JSON.parse(response.body).fetch("data")
    assert_equal user.id, data.fetch("id")
    assert_equal user.email, data.fetch("email")
    assert_equal false, data.fetch("active")
    assert_equal "verified", data.fetch("verification_status")
  end

  test "admin can still read verification status endpoint" do
    user = create_user(email: "verification-endpoint-user@example.com")
    user.update!(verification_status: :verified)
    admin = create_admin(email: "verification-endpoint-admin@example.com")
    access_token = admin_access_token(admin)

    get "/admin/users/#{user.id}/verification-status", headers: {
      "Authorization" => "Bearer #{access_token}"
    }, as: :json

    assert_response :success
    data = JSON.parse(response.body).fetch("data")
    assert_equal user.id, data.fetch("id")
    assert_equal user.email, data.fetch("email")
    assert_equal "verified", data.fetch("verification_status")
    assert_not data.key?("active")
  end

  test "verification status is not exposed in regular user login contract" do
    user = create_user(email: "login-contract-user@example.com")

    post "/auth/login", params: { email: user.email, password: "password123" }, as: :json

    assert_response :success
    data = JSON.parse(response.body).fetch("data")
    assert_not data.key?("verification_status")
  end

  test "returns not found for missing user detail id" do
    admin = create_admin(email: "missing-user-admin@example.com")
    access_token = admin_access_token(admin)

    get "/admin/users/999999", headers: {
      "Authorization" => "Bearer #{access_token}"
    }, as: :json

    assert_response :not_found
    assert_equal "nao encontrado", JSON.parse(response.body)["error"]
  end
end
