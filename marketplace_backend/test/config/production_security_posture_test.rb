require "test_helper"
require "ostruct"

class ProductionSecurityPostureTest < ActiveSupport::TestCase
  ConfigStub = Struct.new(
    :assume_ssl,
    :force_ssl,
    :ssl_options,
    :hosts,
    :host_authorization,
    keyword_init: true
  )

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

  test "configure production enables ssl and explicit hosts" do
    config = ConfigStub.new

    with_env(
      "APP_HOSTS" => "api.example.com,admin.example.com",
      "RAILWAY_PUBLIC_DOMAIN" => "https://rails-api-production.up.railway.app",
      "FORCE_SSL" => "true",
      "ASSUME_SSL" => "true"
    ) do
      ProductionSecurity.configure!(config, env: ENV, rails_env: "production")
    end

    assert_equal true, config.assume_ssl
    assert_equal true, config.force_ssl
    assert_equal ["api.example.com", "admin.example.com", "rails-api-production.up.railway.app"], config.hosts
    assert_equal "/up", healthcheck_path_for(config.ssl_options)
    assert_equal "/up", healthcheck_path_for(config.host_authorization)
  end

  test "configure production raises when hosts are missing" do
    config = ConfigStub.new

    error = assert_raises(ProductionSecurity::ConfigurationError) do
      with_env("APP_HOSTS" => nil, "RAILWAY_PUBLIC_DOMAIN" => nil) do
        ProductionSecurity.configure!(config, env: ENV, rails_env: "production")
      end
    end

    assert_includes error.message, "APP_HOSTS"
  end

  test "production cors origins require explicit env" do
    error = assert_raises(ProductionSecurity::ConfigurationError) do
      with_env("CORS_ALLOWED_ORIGINS" => nil) do
        ProductionSecurity.cors_allowed_origins(env: ENV, rails_env: "production")
      end
    end

    assert_includes error.message, "CORS_ALLOWED_ORIGINS"
  end

  test "non production keeps localhost cors default" do
    with_env("CORS_ALLOWED_ORIGINS" => nil) do
      assert_equal ["http://localhost:4200"], ProductionSecurity.cors_allowed_origins(env: ENV, rails_env: "test")
    end
  end

  test "cors origins can be matched dynamically" do
    with_env("CORS_ALLOWED_ORIGINS" => "https://app.example.com,https://admin.example.com") do
      assert ProductionSecurity.cors_origin_allowed?("https://app.example.com", env: ENV, rails_env: "production")
      refute ProductionSecurity.cors_origin_allowed?("https://evil.example.com", env: ENV, rails_env: "production")
    end
  end

  private

  def healthcheck_path_for(options)
    exclusion = options.dig(:redirect, :exclude) || options[:exclude]
    exclusion.call(OpenStruct.new(path: "/up")) ? "/up" : nil
  end
end
