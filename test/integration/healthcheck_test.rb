require "test_helper"

class HealthcheckTest < ActionDispatch::IntegrationTest
  test "GET /up returns success" do
    get "/up"

    assert_response :success
  end

  test "application exposes healthcheck and signup routes" do
    app_routes = Rails.application.routes.routes.select do |route|
      route.defaults[:controller].present? && !route.path.spec.to_s.start_with?("/rails/")
    end

    assert_equal 2, app_routes.count
    assert_routing "/up", controller: "rails/health", action: "show"
    assert_routing({ method: "post", path: "/auth/signup" }, controller: "auth/signups", action: "create")
  end
end
