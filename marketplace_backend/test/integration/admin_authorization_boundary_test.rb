require "test_helper"

class AdminAuthorizationBoundaryTest < ActionDispatch::IntegrationTest
  def create_user(email: "boundary-user@example.com", password: "password123")
    Users::Create.call(
      email: email,
      password: password,
      password_confirmation: password
    ).user
  end

  def create_admin(email: "boundary-admin@example.com", password: "password123")
    Admin.create!(email: email, password: password, password_confirmation: password)
  end

  def user_access_token(user)
    post "/auth/login", params: { email: user.email, password: "password123" }, as: :json
    JSON.parse(response.body).dig("data", "access_token")
  end

  def admin_access_token(admin)
    post "/admin/auth/login", params: { email: admin.email, password: "password123" }, as: :json
    JSON.parse(response.body).dig("data", "access_token")
  end

  test "user access token is rejected by admin verification status endpoint" do
    user = create_user
    access_token = user_access_token(user)

    get "/admin/users/#{user.id}/verification-status", headers: {
      "Authorization" => "Bearer #{access_token}"
    }, as: :json

    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]
  end

  test "admin access token is rejected by regular user endpoints" do
    admin = create_admin
    access_token = admin_access_token(admin)

    get "/orders", headers: {
      "Authorization" => "Bearer #{access_token}"
    }, as: :json

    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]
  end

  test "forged admin payload does not authenticate without admin signature" do
    admin = create_admin
    forged_token = ::JWT.encode(
      {
        sub: admin.id.to_s,
        jti: SecureRandom.uuid,
        type: "access",
        iat: Time.current.to_i,
        exp: 15.minutes.from_now.to_i,
      },
      Auth::Jwt::Config.access_secret,
      Auth::Jwt::Config.algorithm
    )

    get "/admin/users/999999/verification-status", headers: {
      "Authorization" => "Bearer #{forged_token}"
    }, as: :json

    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]
  end
end
