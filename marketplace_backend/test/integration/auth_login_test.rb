require "test_helper"

class AuthLoginTest < ActionDispatch::IntegrationTest
  def create_user(email: "login@example.com", password: "password123")
    Users::Create.call(
      email: email,
      password: password,
      password_confirmation: password
    ).user
  end

  test "login returns token pair and user data" do
    user = create_user

    post "/auth/login", params: {
      email: user.email,
      password: "password123"
    }, as: :json

    assert_response :success

    body = JSON.parse(response.body)
    data = body.fetch("data")

    assert_equal user.id, data.fetch("id")
    assert_equal user.email, data.fetch("email")
    assert_equal user.profile.id, data.fetch("profile_id")
    assert_equal "Bearer", data.fetch("token_type")
    assert data.fetch("access_token").present?
    assert data.fetch("refresh_token").present?
    assert_equal 15.minutes.to_i, data.fetch("access_expires_in")
    assert_equal 7.days.to_i, data.fetch("refresh_expires_in")
    assert_equal 1, user.refresh_sessions.count
  end

  test "login returns generic invalid credentials for wrong password" do
    user = create_user

    post "/auth/login", params: {
      email: user.email,
      password: "wrong-password"
    }, as: :json

    assert_response :unauthorized
    body = JSON.parse(response.body)
    assert_equal "credenciais invalidas", body["error"]
  end

  test "login returns generic invalid credentials for unknown email" do
    post "/auth/login", params: {
      email: "missing@example.com",
      password: "password123"
    }, as: :json

    assert_response :unauthorized
    body = JSON.parse(response.body)
    assert_equal "credenciais invalidas", body["error"]
  end

  test "login returns generic invalid credentials for inactive user" do
    user = create_user(email: "inactive-login@example.com")
    user.update!(active: false)

    post "/auth/login", params: {
      email: user.email,
      password: "password123"
    }, as: :json

    assert_response :unauthorized
    body = JSON.parse(response.body)
    assert_equal "credenciais invalidas", body["error"]
  end

  test "login returns payload invalido when params are missing" do
    post "/auth/login", params: {}, as: :json

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_equal "payload invalido", body["error"]
  end
end
