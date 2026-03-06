require "test_helper"

class AuthSignupTest < ActionDispatch::IntegrationTest
  test "signup creates user and profile" do
    post "/auth/signup", params: {
      user: {
        email: "signup@example.com",
        password: "password123",
        password_confirmation: "password123",
      },
    }, as: :json

    assert_response :created

    body = JSON.parse(response.body)
    assert body.dig("data", "id").present?
    assert_equal "signup@example.com", body.dig("data", "email")
    assert body.dig("data", "profile_id").present?
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
end
