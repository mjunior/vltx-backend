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

    assert_equal 46, app_routes.count
    assert_routing "/up", controller: "rails/health", action: "show"
    assert_routing({ method: "get", path: "/admin/dashboard" }, controller: "admin/dashboard", action: "show")
    assert_routing({ method: "get", path: "/admin/users" }, controller: "admin/users", action: "index")
    assert_routing({ method: "get", path: "/admin/users/123" }, controller: "admin/users", action: "show", id: "123")
    assert_routing({ method: "patch", path: "/admin/users/123" }, controller: "admin/users", action: "update", id: "123")
    assert_routing({ method: "patch", path: "/admin/users/123/deactivate" }, controller: "admin/users", action: "deactivate", id: "123")
    assert_routing({ method: "post", path: "/admin/users/123/balance-adjustments" }, controller: "admin/user_balance_adjustments", action: "create", id: "123")
    assert_routing({ method: "get", path: "/admin/products" }, controller: "admin/products", action: "index")
    assert_routing({ method: "get", path: "/admin/products/123" }, controller: "admin/products", action: "show", id: "123")
    assert_routing({ method: "patch", path: "/admin/products/123/soft_delete" }, controller: "admin/products", action: "soft_delete", id: "123")
    assert_routing({ method: "get", path: "/admin/orders" }, controller: "admin/orders", action: "index")
    assert_routing({ method: "get", path: "/admin/orders/123" }, controller: "admin/orders", action: "show", id: "123")
    assert_routing({ method: "post", path: "/admin/orders/123/approve" }, controller: "admin/orders", action: "approve", id: "123")
    assert_routing({ method: "post", path: "/admin/orders/123/deny" }, controller: "admin/orders", action: "deny", id: "123")
    assert_routing({ method: "get", path: "/public/products" }, controller: "public/products", action: "index")
    assert_routing({ method: "get", path: "/public/products/123" }, controller: "public/products", action: "show", id: "123")
    assert_routing({ method: "get", path: "/wallet" }, controller: "wallets", action: "show")
    assert_routing({ method: "get", path: "/wallet/transactions" }, controller: "wallets", action: "transactions")
    assert_routing({ method: "get", path: "/orders" }, controller: "orders", action: "index")
    assert_routing({ method: "get", path: "/orders/123" }, controller: "orders", action: "show", id: "123")
    assert_routing({ method: "post", path: "/orders/123/advance" }, controller: "orders", action: "advance", id: "123")
    assert_routing({ method: "post", path: "/orders/123/cancel" }, controller: "orders", action: "cancel", id: "123")
    assert_routing({ method: "post", path: "/orders/123/deliver" }, controller: "orders", action: "deliver", id: "123")
    assert_routing({ method: "post", path: "/orders/123/contest" }, controller: "orders", action: "contest", id: "123")
    assert_routing({ method: "post", path: "/orders/123/approve_contest" }, controller: "orders", action: "approve_contest", id: "123")
    assert_routing({ method: "post", path: "/orders/123/items/456/rating" }, controller: "order_item_ratings", action: "create", order_id: "123", id: "456")
    assert_routing({ method: "post", path: "/cart" }, controller: "carts", action: "create")
    assert_routing({ method: "post", path: "/cart/checkout" }, controller: "cart_checkout", action: "create")
    assert_routing({ method: "post", path: "/cart/items" }, controller: "cart_items", action: "create")
    assert_routing({ method: "patch", path: "/cart/items/123" }, controller: "cart_items", action: "update", id: "123")
    assert_routing({ method: "delete", path: "/cart/items/123" }, controller: "cart_items", action: "destroy", id: "123")
    assert_routing({ method: "patch", path: "/profile" }, controller: "profiles", action: "update")
    assert_routing({ method: "get", path: "/products" }, controller: "products", action: "index")
    assert_routing({ method: "post", path: "/products" }, controller: "products", action: "create")
    assert_routing({ method: "patch", path: "/products/123" }, controller: "products", action: "update", id: "123")
    assert_routing({ method: "patch", path: "/products/123/deactivate" }, controller: "products", action: "deactivate", id: "123")
    assert_routing({ method: "delete", path: "/products/123" }, controller: "products", action: "destroy", id: "123")
    assert_routing({ method: "get", path: "/seller/finance" }, controller: "seller_finance", action: "show")
    assert_routing({ method: "post", path: "/auth/signup" }, controller: "auth/signups", action: "create")
    assert_routing({ method: "post", path: "/auth/login" }, controller: "auth/logins", action: "create")
    assert_routing({ method: "post", path: "/auth/refresh" }, controller: "auth/refreshes", action: "create")
    assert_routing({ method: "post", path: "/auth/logout" }, controller: "auth/logouts", action: "create")
  end
end
