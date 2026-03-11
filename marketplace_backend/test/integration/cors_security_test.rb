require "test_helper"

class CorsSecurityTest < ActionDispatch::IntegrationTest
  def with_env(overrides)
    previous = {}

    overrides.each do |key, value|
      previous[key] = ENV.key?(key) ? ENV[key] : :__missing__
      value.nil? ? ENV.delete(key) : ENV[key] = value
    end

    yield
  ensure
    previous.each do |key, value|
      value == :__missing__ ? ENV.delete(key) : ENV[key] = value
    end
  end

  test "allowed origin receives allow origin header" do
    with_env("CORS_ALLOWED_ORIGINS" => "https://app.example.com") do
      get "/up", headers: {
        "Origin" => "https://app.example.com"
      }
    end

    assert_response :success
    assert_equal "https://app.example.com", response.headers["Access-Control-Allow-Origin"]
    assert_equal "Origin", response.headers["Vary"]
  end

  test "disallowed origin does not receive allow origin header" do
    with_env("CORS_ALLOWED_ORIGINS" => "https://app.example.com") do
      get "/up", headers: {
        "Origin" => "https://evil.example.com"
      }
    end

    assert_response :success
    assert_nil response.headers["Access-Control-Allow-Origin"]
  end

  test "allowed preflight responds with cors headers" do
    with_env("CORS_ALLOWED_ORIGINS" => "https://app.example.com") do
      process :options, "/auth/login", headers: {
        "Origin" => "https://app.example.com",
        "Access-Control-Request-Method" => "POST",
        "Access-Control-Request-Headers" => "Content-Type, Authorization"
      }
    end

    assert_response :success
    assert_equal "https://app.example.com", response.headers["Access-Control-Allow-Origin"]
    assert_includes response.headers["Access-Control-Allow-Methods"], "POST"
  end
end
