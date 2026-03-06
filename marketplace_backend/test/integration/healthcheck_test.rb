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

    assert_equal 13, app_routes.count
    assert_routing "/up", controller: "rails/health", action: "show"
    assert_routing({ method: "get", path: "/public/products" }, controller: "public/products", action: "index")
    assert_routing({ method: "get", path: "/public/products/123" }, controller: "public/products", action: "show", id: "123")
    assert_routing({ method: "patch", path: "/profile" }, controller: "profiles", action: "update")
    assert_routing({ method: "get", path: "/products" }, controller: "products", action: "index")
    assert_routing({ method: "post", path: "/products" }, controller: "products", action: "create")
    assert_routing({ method: "patch", path: "/products/123" }, controller: "products", action: "update", id: "123")
    assert_routing({ method: "patch", path: "/products/123/deactivate" }, controller: "products", action: "deactivate", id: "123")
    assert_routing({ method: "delete", path: "/products/123" }, controller: "products", action: "destroy", id: "123")
    assert_routing({ method: "post", path: "/auth/signup" }, controller: "auth/signups", action: "create")
    assert_routing({ method: "post", path: "/auth/login" }, controller: "auth/logins", action: "create")
    assert_routing({ method: "post", path: "/auth/refresh" }, controller: "auth/refreshes", action: "create")
    assert_routing({ method: "post", path: "/auth/logout" }, controller: "auth/logouts", action: "create")
  end
end
