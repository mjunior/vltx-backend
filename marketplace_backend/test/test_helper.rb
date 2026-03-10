ENV["RAILS_ENV"] ||= "test"
ENV["JWT_ACCESS_SECRET"] ||= "test_access_secret_1234567890"
ENV["JWT_REFRESH_SECRET"] ||= "test_refresh_secret_1234567890"
ENV["JWT_REFRESH_PEPPER"] ||= "test_refresh_pepper_1234567890"
ENV["ADMIN_JWT_ACCESS_SECRET"] ||= "test_admin_access_secret_1234567890"
ENV["ADMIN_JWT_REFRESH_SECRET"] ||= "test_admin_refresh_secret_1234567890"
ENV["ADMIN_JWT_REFRESH_PEPPER"] ||= "test_admin_refresh_pepper_1234567890"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
