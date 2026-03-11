require "test_helper"
require "cgi"

class AuthPasswordResetTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers

  REQUEST_THROTTLE_IP = "198.51.100.21".freeze
  CONFIRM_THROTTLE_IP = "198.51.100.22".freeze

  def create_user(email: "reset@example.com", password: "password123", active: true)
    user = Users::Create.call(
      email: email,
      password: password,
      password_confirmation: password
    ).user
    user.update!(active: active)
    user
  end

  def login_and_get_refresh_token(user, password: "password123")
    post "/auth/login", params: {
      email: user.email,
      password: password
    }, as: :json

    JSON.parse(response.body).dig("data", "refresh_token")
  end

  def with_stubbed_password_reset(callable)
    singleton = EmailService.singleton_class
    original_method = EmailService.method(:password_reset)

    singleton.send(:define_method, :password_reset, callable)
    yield
  ensure
    singleton.send(:define_method, :password_reset, original_method)
  end

  test "request returns generic accepted and sends email for active user" do
    user = create_user
    captured = nil

    with_stubbed_password_reset(->(to:, reset_link:) {
      captured = { to:, reset_link: }
      EmailService::Result.new(success?: true, provider_id: "email_123")
    }) do
      post "/auth/password-reset", params: { email: user.email }, as: :json
    end

    assert_response :accepted
    body = JSON.parse(response.body)
    assert_equal "se o e-mail existir, enviaremos instrucoes para redefinir a senha", body["message"]
    assert_equal user.email, captured[:to]
    assert_includes captured[:reset_link], ENV["FRONTEND_RESET_PASSWORD_URL"]
    token = CGI.unescape(captured[:reset_link].split("token=").last)
    assert_equal user.id, User.find_by_token_for(:password_reset, token)&.id
  end

  test "request returns same accepted response for unknown email without sending email" do
    called = false

    with_stubbed_password_reset(->(**) { called = true }) do
      post "/auth/password-reset", params: { email: "missing@example.com" }, as: :json
    end

    assert_response :accepted
    assert_equal "se o e-mail existir, enviaremos instrucoes para redefinir a senha", JSON.parse(response.body)["message"]
    assert_equal false, called
  end

  test "request returns same accepted response for inactive user without sending email" do
    user = create_user(email: "inactive-reset@example.com", active: false)
    called = false

    with_stubbed_password_reset(->(**) { called = true }) do
      post "/auth/password-reset", params: { email: user.email }, as: :json
    end

    assert_response :accepted
    assert_equal false, called
  end

  test "request returns payload invalido for missing email" do
    post "/auth/password-reset", params: {}, as: :json

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
  end

  test "request throttles bursts by ip" do
    5.times do
      post "/auth/password-reset", params: { email: "missing@example.com" }, headers: {
        "REMOTE_ADDR" => REQUEST_THROTTLE_IP
      }, as: :json
    end

    post "/auth/password-reset", params: { email: "missing@example.com" }, headers: {
      "REMOTE_ADDR" => REQUEST_THROTTLE_IP
    }, as: :json

    assert_response :too_many_requests
    assert_equal "muitas requisicoes", JSON.parse(response.body)["error"]
    assert_equal "900", response.headers["Retry-After"]
  end

  test "confirm resets password and revokes refresh sessions" do
    user = create_user
    refresh_token = login_and_get_refresh_token(user)
    assert refresh_token.present?

    token = user.issue_password_reset_token!

    post "/auth/password-reset/confirm", params: {
      token: token,
      password: "newpassword123",
      password_confirmation: "newpassword123"
    }, as: :json

    assert_response :no_content
    assert user.reload.authenticate("newpassword123")
    assert_equal 0, user.refresh_sessions.active.count
    assert_nil User.find_by_token_for(:password_reset, token)
  end

  test "confirm rejects expired token" do
    user = create_user
    token = user.issue_password_reset_token!

    travel 16.minutes do
      post "/auth/password-reset/confirm", params: {
        token: token,
        password: "newpassword123",
        password_confirmation: "newpassword123"
      }, as: :json
    end

    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]
  end

  test "confirm rejects reused token" do
    user = create_user
    token = user.issue_password_reset_token!

    post "/auth/password-reset/confirm", params: {
      token: token,
      password: "newpassword123",
      password_confirmation: "newpassword123"
    }, as: :json
    assert_response :no_content

    post "/auth/password-reset/confirm", params: {
      token: token,
      password: "anotherpassword123",
      password_confirmation: "anotherpassword123"
    }, as: :json

    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]
  end

  test "confirm rejects old token after new request invalidates previous one" do
    user = create_user
    old_token = user.issue_password_reset_token!
    new_token = user.issue_password_reset_token!

    post "/auth/password-reset/confirm", params: {
      token: old_token,
      password: "newpassword123",
      password_confirmation: "newpassword123"
    }, as: :json

    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]

    post "/auth/password-reset/confirm", params: {
      token: new_token,
      password: "newpassword123",
      password_confirmation: "newpassword123"
    }, as: :json

    assert_response :no_content
  end

  test "confirm rejects inactive user token" do
    user = create_user(active: false)
    user.update!(password_reset_nonce: SecureRandom.hex(16))
    token = user.generate_token_for(:password_reset)

    post "/auth/password-reset/confirm", params: {
      token: token,
      password: "newpassword123",
      password_confirmation: "newpassword123"
    }, as: :json

    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]
  end

  test "confirm rejects payload with unknown fields" do
    user = create_user
    token = user.issue_password_reset_token!

    post "/auth/password-reset/confirm", params: {
      token: token,
      password: "newpassword123",
      password_confirmation: "newpassword123",
      email: user.email
    }, as: :json

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
  end

  test "confirm throttles bursts by ip" do
    10.times do
      post "/auth/password-reset/confirm", params: {
        token: "bad-token",
        password: "newpassword123",
        password_confirmation: "newpassword123"
      }, headers: {
        "REMOTE_ADDR" => CONFIRM_THROTTLE_IP
      }, as: :json
    end

    post "/auth/password-reset/confirm", params: {
      token: "bad-token",
      password: "newpassword123",
      password_confirmation: "newpassword123"
    }, headers: {
      "REMOTE_ADDR" => CONFIRM_THROTTLE_IP
    }, as: :json

    assert_response :too_many_requests
    assert_equal "muitas requisicoes", JSON.parse(response.body)["error"]
    assert_equal "900", response.headers["Retry-After"]
  end
end
