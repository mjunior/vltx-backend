require "test_helper"

class AuthSignupTest < ActionDispatch::IntegrationTest
  test "signup creates user/profile and returns token pair contract" do
    post "/auth/signup", params: {
      user: {
        email: "signup@example.com",
        password: "password123",
        password_confirmation: "password123",
      },
    }, as: :json

    assert_response :created

    body = JSON.parse(response.body)
    data = body.fetch("data")

    assert data.fetch("id").present?
    assert_equal "signup@example.com", data.fetch("email")
    assert data.fetch("profile_id").present?
    assert_equal "Bearer", data.fetch("token_type")
    assert data.fetch("access_token").present?
    assert data.fetch("refresh_token").present?
    assert_equal 15.minutes.to_i, data.fetch("access_expires_in")
    assert_equal 7.days.to_i, data.fetch("refresh_expires_in")

    user = User.find(data.fetch("id"))
    assert_equal 1, user.refresh_sessions.count
  end

  test "signup returns generic message when email already exists" do
    post "/auth/signup", params: {
      user: {
        email: "duplicate@example.com",
        password: "password123",
        password_confirmation: "password123",
      },
    }, as: :json

    assert_response :created

    post "/auth/signup", params: {
      user: {
        email: "DUPLICATE@EXAMPLE.COM",
        password: "password123",
        password_confirmation: "password123",
      },
    }, as: :json

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)
    assert_equal "cadastro invalido", body["error"]
  end

  test "signup returns generic message when confirmation is invalid" do
    post "/auth/signup", params: {
      user: {
        email: "wrong-confirm@example.com",
        password: "password123",
        password_confirmation: "different",
      },
    }, as: :json

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)
    assert_equal "cadastro invalido", body["error"]
  end

  test "signup returns generic message when email format is invalid" do
    post "/auth/signup", params: {
      user: {
        email: "not-an-email",
        password: "password123",
        password_confirmation: "password123",
      },
    }, as: :json

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)
    assert_equal "cadastro invalido", body["error"]
  end

  test "signup returns generic message when payload does not include user root key" do
    post "/auth/signup", params: {
      email: "missing-root@example.com",
      password: "password123",
      password_confirmation: "password123",
    }, as: :json

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)
    assert_equal "cadastro invalido", body["error"]
  end
end
