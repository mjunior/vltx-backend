require "test_helper"

class AdminUsersUpdateTest < ActionDispatch::IntegrationTest
  def create_user(email: "admin-update-user@example.com", password: "password123", active: true)
    user = Users::Create.call(email: email, password: password, password_confirmation: password).user
    user.update!(active: active)
    user
  end

  def create_admin(email: "admin-update@example.com", password: "password123")
    Admin.create!(email: email, password: password, password_confirmation: password)
  end

  def admin_access_token(admin)
    post "/admin/auth/login", params: { email: admin.email, password: "password123" }, as: :json
    JSON.parse(response.body).dig("data", "access_token")
  end

  test "admin updates email verification status and profile fields" do
    user = create_user
    admin = create_admin
    admin_token = admin_access_token(admin)

    patch "/admin/users/#{user.id}", params: {
      email: "updated-admin-user@example.com",
      verification_status: "verified",
      name: "Admin Editado",
      address: "Rua Admin, 100",
      photo_url: "https://cdn.example.com/avatar.png"
    }, headers: {
      "Authorization" => "Bearer #{admin_token}",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    assert_response :success
    body = JSON.parse(response.body).fetch("data")
    assert_equal user.id, body.fetch("id")
    assert_equal "updated-admin-user@example.com", body.fetch("email")
    assert_equal "verified", body.fetch("verification_status")
    assert_equal "Admin Editado", body.dig("profile", "name")
    assert_equal "Rua Admin, 100", body.dig("profile", "address")
    assert_equal "https://cdn.example.com/avatar.png", body.dig("profile", "photo_url")

    user.reload
    user.profile.reload
    assert_equal "updated-admin-user@example.com", user.email
    assert_equal "verified", user.verification_status
    assert_equal "Admin Editado", user.profile.full_name
    assert_equal "Rua Admin, 100", user.profile.address
    assert_equal "https://cdn.example.com/avatar.png", user.profile.photo_url
  end

  test "admin can deactivate active user through patch" do
    user = create_user(email: "admin-patch-deactivate@example.com")
    admin = create_admin(email: "admin-patch-deactivate@example.com")
    admin_token = admin_access_token(admin)

    patch "/admin/users/#{user.id}", params: {
      active: false
    }, headers: {
      "Authorization" => "Bearer #{admin_token}",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    assert_response :success
    assert_equal false, JSON.parse(response.body).dig("data", "active")
    assert_equal false, user.reload.active
  end

  test "admin can reactivate inactive user only with active true" do
    user = create_user(email: "admin-reactivate-user@example.com", active: false)
    admin = create_admin(email: "admin-reactivate-user@example.com")
    admin_token = admin_access_token(admin)

    patch "/admin/users/#{user.id}", params: {
      active: true
    }, headers: {
      "Authorization" => "Bearer #{admin_token}",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    assert_response :success
    assert_equal true, JSON.parse(response.body).dig("data", "active")
    assert_equal true, user.reload.active
  end

  test "returns payload invalido when inactive user receives other changes" do
    user = create_user(email: "inactive-admin-update@example.com", active: false)
    admin = create_admin(email: "inactive-admin-update@example.com")
    admin_token = admin_access_token(admin)

    patch "/admin/users/#{user.id}", params: {
      active: true,
      name: "Nao pode junto"
    }, headers: {
      "Authorization" => "Bearer #{admin_token}",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
    assert_equal false, user.reload.active
  end

  test "returns payload invalido for duplicate email" do
    create_user(email: "occupied-admin-email@example.com")
    user = create_user(email: "free-admin-email@example.com")
    admin = create_admin(email: "duplicate-admin-email@example.com")
    admin_token = admin_access_token(admin)

    patch "/admin/users/#{user.id}", params: {
      email: "occupied-admin-email@example.com"
    }, headers: {
      "Authorization" => "Bearer #{admin_token}",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
  end

  test "returns payload invalido for empty payload" do
    user = create_user(email: "empty-admin-update@example.com")
    admin = create_admin(email: "empty-admin-update@example.com")
    admin_token = admin_access_token(admin)

    patch "/admin/users/#{user.id}", params: {}, headers: {
      "Authorization" => "Bearer #{admin_token}",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
  end
end
