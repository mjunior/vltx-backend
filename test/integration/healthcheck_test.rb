require "test_helper"

class HealthcheckTest < ActionDispatch::IntegrationTest
  test "GET /up returns success" do
    get "/up"

    assert_response :success
  end

  test "application exposes only healthcheck route" do
    app_routes = Rails.application.routes.routes.select do |route|
      route.defaults[:controller].present? && !route.path.spec.to_s.start_with?("/rails/")
    end

    assert_equal 1, app_routes.count
    assert_routing "/up", controller: "rails/health", action: "show"
  end
end
