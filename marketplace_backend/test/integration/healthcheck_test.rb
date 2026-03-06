require "test_helper"

class HealthcheckTest < ActionDispatch::IntegrationTest
  test "GET /up returns success" do
    get "/up"

    assert_response :success
  end

  test "application exposes healthcheck and auth routes" do
    app_routes = Rails.application.routes.routes.select do |route|
      route.defaults[:controller].present? && !route.path.spec.to_s.start_with?("/rails/")
    end

    assert_equal 6, app_routes.count
    assert_routing "/up", controller: "rails/health", action: "show"
    assert_routing({ method: "patch", path: "/profile" }, controller: "profiles", action: "update")
    assert_routing({ method: "post", path: "/auth/signup" }, controller: "auth/signups", action: "create")
    assert_routing({ method: "post", path: "/auth/login" }, controller: "auth/logins", action: "create")
    assert_routing({ method: "post", path: "/auth/refresh" }, controller: "auth/refreshes", action: "create")
    assert_routing({ method: "post", path: "/auth/logout" }, controller: "auth/logouts", action: "create")
  end
end
