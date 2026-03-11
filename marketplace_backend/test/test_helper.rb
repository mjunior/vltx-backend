ENV["RAILS_ENV"] ||= "test"
ENV["JWT_ACCESS_SECRET"] = "test_access_secret_1234567890"
ENV["JWT_REFRESH_SECRET"] = "test_refresh_secret_1234567890"
ENV["JWT_REFRESH_PEPPER"] = "test_refresh_pepper_1234567890"
ENV["ADMIN_JWT_ACCESS_SECRET"] = "test_admin_access_secret_1234567890"
ENV["ADMIN_JWT_REFRESH_SECRET"] = "test_admin_refresh_secret_1234567890"
ENV["ADMIN_JWT_REFRESH_PEPPER"] = "test_admin_refresh_pepper_1234567890"
ENV["DATABASE_URL"] = "postgresql://localhost/marketplace_backend_test"
ENV["CLOUDFLARE_R2_BUCKET"] = "test-bucket"
ENV["CLOUDFLARE_R2_ENDPOINT"] = "https://example.r2.cloudflarestorage.com"
ENV["CLOUDFLARE_R2_ACCESS_KEY_ID"] = "test_access_key"
ENV["CLOUDFLARE_R2_SECRET_ACCESS_KEY"] = "test_secret_key"
ENV["CLOUDFLARE_R2_PUBLIC_BASE_URL"] = "https://public.example.r2.dev"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    setup do
      next unless defined?(Rack::Attack)

      Rack::Attack.reset!
      Rack::Attack.cache.store.clear if Rack::Attack.cache.store.respond_to?(:clear)
    end
  end
end
