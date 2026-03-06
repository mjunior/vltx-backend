require "test_helper"

class ProfileUpdateTest < ActionDispatch::IntegrationTest
  def create_user(email: "profile-update@example.com", password: "password123")
    Users::Create.call(
      email: email,
      password: password,
      password_confirmation: password
    ).user
  end

  def access_token_for(user, password: "password123")
    post "/auth/login", params: {
      email: user.email,
      password: password
    }, as: :json

    JSON.parse(response.body).dig("data", "access_token")
  end

  test "updates own profile with name and address" do
    user = create_user
    access_token = access_token_for(user)

    patch "/profile", params: {
      name: "Joao Silva",
      address: "Rua A, 123"
    }, headers: {
      "Authorization" => "Bearer #{access_token}",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    assert_response :success

    body = JSON.parse(response.body)
    assert_equal user.profile.id, body.dig("data", "id")
    assert_equal "Joao Silva", body.dig("data", "name")
    assert_equal "Rua A, 123", body.dig("data", "address")

    user.profile.reload
    assert_equal "Joao Silva", user.profile.full_name
    assert_equal "Rua A, 123", user.profile.address
  end

  test "patch keeps absent fields unchanged" do
    user = create_user(email: "partial-profile@example.com")
    user.profile.update!(full_name: "Nome Antigo", address: "Endereco Antigo")
    access_token = access_token_for(user)

    patch "/profile", params: {
      name: "Nome Novo"
    }, headers: {
      "Authorization" => "Bearer #{access_token}",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    assert_response :success

    user.profile.reload
    assert_equal "Nome Novo", user.profile.full_name
    assert_equal "Endereco Antigo", user.profile.address
  end

  test "patch clears field when value is null" do
    user = create_user(email: "clear-profile@example.com")
    user.profile.update!(full_name: "Nome", address: "Endereco")
    access_token = access_token_for(user)

    patch "/profile", params: {
      address: nil
    }, headers: {
      "Authorization" => "Bearer #{access_token}",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    assert_response :success

    user.profile.reload
    assert_equal "Nome", user.profile.full_name
    assert_nil user.profile.address
  end

  test "returns token invalido without authorization header" do
    patch "/profile", params: { name: "Any" }, as: :json

    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]
  end

  test "returns token invalido for malformed bearer token" do
    patch "/profile", params: { name: "Any" }, headers: {
      "Authorization" => "Bearer invalid-token",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]
  end

  test "returns payload invalido for unknown owner fields" do
    user = create_user(email: "owner-forge@example.com")
    other_user = create_user(email: "other-owner@example.com")
    access_token = access_token_for(user)

    patch "/profile", params: {
      user_id: other_user.id,
      owner_id: other_user.id,
      name: "Tentativa de forja"
    }, headers: {
      "Authorization" => "Bearer #{access_token}",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]

    user.profile.reload
    other_user.profile.reload
    assert_nil user.profile.full_name
    assert_nil other_user.profile.full_name
  end

  test "returns payload invalido for non-json content type" do
    user = create_user(email: "non-json-profile@example.com")
    access_token = access_token_for(user)

    patch "/profile", params: "name=abc", headers: {
      "Authorization" => "Bearer #{access_token}",
      "CONTENT_TYPE" => "application/x-www-form-urlencoded"
    }

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
  end
end
