require "test_helper"

class AuthReuseIncidentTest < ActionDispatch::IntegrationTest
  class LoggerDouble
    attr_reader :warn_payloads

    def initialize(raise_on_warn: false)
      @raise_on_warn = raise_on_warn
      @warn_payloads = []
    end

    def warn(message)
      raise StandardError, "logger unavailable" if @raise_on_warn

      @warn_payloads << message
    end

    def info(*); end
    def error(*); end
    def debug(*); end
  end

  def with_logger(temp_logger)
    previous_logger = Rails.logger
    Rails.logger = temp_logger
    yield
  ensure
    Rails.logger = previous_logger
  end

  def create_user(email: "incident@example.com", password: "password123")
    Users::Create.call(
      email: email,
      password: password,
      password_confirmation: password
    ).user
  end

  def login_tokens(user, password: "password123")
    post "/auth/login", params: {
      email: user.email,
      password: password
    }, as: :json

    JSON.parse(response.body).fetch("data")
  end

  test "reusing previous refresh token triggers global revoke and blocks current refresh" do
    user = create_user
    login_data = login_tokens(user)
    refresh_token_1 = login_data.fetch("refresh_token")

    post "/auth/refresh", params: { refresh_token: refresh_token_1 }, as: :json
    assert_response :success
    refresh_token_2 = JSON.parse(response.body).dig("data", "refresh_token")

    post "/auth/refresh", params: { refresh_token: refresh_token_1 }, as: :json
    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]

    post "/auth/refresh", params: { refresh_token: refresh_token_2 }, as: :json
    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]

    new_login = login_tokens(user)
    assert new_login.fetch("refresh_token").present?
  end

  test "reuse incident emits a security log entry" do
    user = create_user(email: "incident-log@example.com")
    login_data = login_tokens(user)
    refresh_token_1 = login_data.fetch("refresh_token")

    post "/auth/refresh", params: { refresh_token: refresh_token_1 }, as: :json
    assert_response :success

    logger = LoggerDouble.new

    with_logger(logger) do
      post "/auth/refresh", params: { refresh_token: refresh_token_1 }, as: :json
    end

    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]

    assert_equal 1, logger.warn_payloads.size
    parsed = JSON.parse(logger.warn_payloads.first)
    assert_equal "auth.refresh_reuse_detected", parsed["event"]
    assert_equal user.id, parsed["user_id"]
  end

  test "reuse incident still revokes sessions when logging fails" do
    user = create_user(email: "incident-log-failure@example.com")
    login_data = login_tokens(user)
    refresh_token_1 = login_data.fetch("refresh_token")

    post "/auth/refresh", params: { refresh_token: refresh_token_1 }, as: :json
    assert_response :success
    refresh_token_2 = JSON.parse(response.body).dig("data", "refresh_token")

    logger = LoggerDouble.new(raise_on_warn: true)

    with_logger(logger) do
      post "/auth/refresh", params: { refresh_token: refresh_token_1 }, as: :json
    end

    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]

    post "/auth/refresh", params: { refresh_token: refresh_token_2 }, as: :json
    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]
  end
end
