class Rack::Attack
  THROTTLED_RESPONSE = { error: "muitas requisicoes" }.freeze
  CART_ITEM_PATH = %r{\A/cart/items(?:/[^/]+)?\z}.freeze
  ADMIN_BALANCE_ADJUSTMENTS_PATH = %r{\A/admin/users/[^/]+/balance-adjustments\z}.freeze
  ADMIN_DEACTIVATE_PATH = %r{\A/admin/users/[^/]+/deactivate\z}.freeze
  ADMIN_SOFT_DELETE_PATH = %r{\A/admin/products/[^/]+/soft_delete\z}.freeze
  ADMIN_ORDER_APPROVE_PATH = %r{\A/admin/orders/[^/]+/approve\z}.freeze
  ADMIN_ORDER_DENY_PATH = %r{\A/admin/orders/[^/]+/deny\z}.freeze
  PRODUCT_UPDATE_PATH = %r{\A/products/[^/]+\z}.freeze
  PRODUCT_DEACTIVATE_PATH = %r{\A/products/[^/]+/deactivate\z}.freeze
  PASSWORD_RESET_CONFIRM_PATH = "/auth/password-reset/confirm".freeze

  class << self
    def actor_discriminator_for(request, namespace:)
      header = request.get_header("HTTP_AUTHORIZATION")
      actor_id =
        case namespace
        when :admin
          admin_id_from(header)
        else
          user_id_from(header)
        end

      actor_id.present? ? "actor:#{actor_id}" : "ip:#{request.ip}"
    end

    def user_id_from(header)
      token = bearer_token_from(header)
      return if token.blank?

      Auth::Jwt::Verifier.verify!(token: token, expected_type: "access").payload["sub"]
    rescue Auth::Jwt::Errors::InvalidToken
      nil
    end

    def admin_id_from(header)
      token = bearer_token_from(header)
      return if token.blank?

      AdminAuth::Jwt::Verifier.verify!(token: token, expected_type: "access").payload["sub"]
    rescue AdminAuth::Jwt::Errors::InvalidToken
      nil
    end

    def bearer_token_from(header)
      return if header.blank?

      scheme, token = header.to_s.split(" ", 2)
      return unless scheme == "Bearer"

      token
    end

    def cart_checkout?(request)
      request.post? && request.path == "/cart/checkout"
    end

    def cart_item_mutation?(request)
      request.path.match?(CART_ITEM_PATH) && (request.post? || request.patch? || request.delete?)
    end

    def admin_balance_adjustment?(request)
      request.post? && request.path.match?(ADMIN_BALANCE_ADJUSTMENTS_PATH)
    end

    def admin_deactivate?(request)
      request.patch? && request.path.match?(ADMIN_DEACTIVATE_PATH)
    end

    def admin_soft_delete?(request)
      request.patch? && request.path.match?(ADMIN_SOFT_DELETE_PATH)
    end

    def admin_order_approve?(request)
      request.post? && request.path.match?(ADMIN_ORDER_APPROVE_PATH)
    end

    def admin_order_deny?(request)
      request.post? && request.path.match?(ADMIN_ORDER_DENY_PATH)
    end

    def product_create?(request)
      request.post? && request.path == "/products"
    end

    def product_update?(request)
      request.patch? && request.path.match?(PRODUCT_UPDATE_PATH)
    end

    def product_deactivate?(request)
      request.patch? && request.path.match?(PRODUCT_DEACTIVATE_PATH)
    end

    def product_delete?(request)
      request.delete? && request.path.match?(PRODUCT_UPDATE_PATH)
    end

    def password_reset_request?(request)
      request.post? && request.path == "/auth/password-reset"
    end

    def password_reset_confirm?(request)
      request.post? && request.path == PASSWORD_RESET_CONFIRM_PATH
    end
  end

  if defined?(Rails) && Rails.cache
    Rack::Attack.cache.store =
      if Rails.cache.is_a?(ActiveSupport::Cache::NullStore)
        ActiveSupport::Cache::MemoryStore.new
      else
        Rails.cache
      end
  end

  safelist("allow-healthcheck") do |request|
    request.path == "/up"
  end

  throttle("auth/signup/ip", limit: 5, period: 60.seconds) do |request|
    request.ip if request.post? && request.path == "/auth/signup"
  end

  throttle("auth/login/ip", limit: 5, period: 20.seconds) do |request|
    request.ip if request.post? && request.path == "/auth/login"
  end

  throttle("auth/refresh/ip", limit: 10, period: 60.seconds) do |request|
    request.ip if request.post? && request.path == "/auth/refresh"
  end

  throttle("auth/password-reset/ip", limit: 5, period: 15.minutes) do |request|
    request.ip if password_reset_request?(request)
  end

  throttle("auth/password-reset/confirm/ip", limit: 10, period: 15.minutes) do |request|
    request.ip if password_reset_confirm?(request)
  end

  throttle("admin/auth/login/ip", limit: 3, period: 20.seconds) do |request|
    request.ip if request.post? && request.path == "/admin/auth/login"
  end

  throttle("admin/auth/refresh/ip", limit: 5, period: 60.seconds) do |request|
    request.ip if request.post? && request.path == "/admin/auth/refresh"
  end

  throttle("cart/checkout/actor", limit: 5, period: 60.seconds) do |request|
    next unless cart_checkout?(request)

    "cart-checkout:#{actor_discriminator_for(request, namespace: :user)}"
  end

  throttle("cart/items/actor", limit: 20, period: 60.seconds) do |request|
    next unless cart_item_mutation?(request)

    "cart-items:#{request.request_method.downcase}:#{actor_discriminator_for(request, namespace: :user)}"
  end

  throttle("products/create/actor", limit: 5, period: 10.minutes) do |request|
    next unless product_create?(request)

    "products-create:#{actor_discriminator_for(request, namespace: :user)}"
  end

  throttle("products/update/actor", limit: 15, period: 10.minutes) do |request|
    next unless product_update?(request)

    "products-update:#{actor_discriminator_for(request, namespace: :user)}"
  end

  throttle("products/deactivate/actor", limit: 10, period: 10.minutes) do |request|
    next unless product_deactivate?(request)

    "products-deactivate:#{actor_discriminator_for(request, namespace: :user)}"
  end

  throttle("products/delete/actor", limit: 10, period: 10.minutes) do |request|
    next unless product_delete?(request)

    "products-delete:#{actor_discriminator_for(request, namespace: :user)}"
  end

  throttle("admin/balance-adjustments/actor", limit: 5, period: 60.seconds) do |request|
    next unless admin_balance_adjustment?(request)

    "admin-balance-adjustments:#{actor_discriminator_for(request, namespace: :admin)}"
  end

  throttle("admin/users/deactivate/actor", limit: 5, period: 60.seconds) do |request|
    next unless admin_deactivate?(request)

    "admin-users-deactivate:#{actor_discriminator_for(request, namespace: :admin)}"
  end

  throttle("admin/products/soft-delete/actor", limit: 5, period: 60.seconds) do |request|
    next unless admin_soft_delete?(request)

    "admin-products-soft-delete:#{actor_discriminator_for(request, namespace: :admin)}"
  end

  throttle("admin/orders/approve/actor", limit: 5, period: 60.seconds) do |request|
    next unless admin_order_approve?(request)

    "admin-orders-approve:#{actor_discriminator_for(request, namespace: :admin)}"
  end

  throttle("admin/orders/deny/actor", limit: 5, period: 60.seconds) do |request|
    next unless admin_order_deny?(request)

    "admin-orders-deny:#{actor_discriminator_for(request, namespace: :admin)}"
  end

  self.throttled_responder = lambda do |request|
    data = request.env["rack.attack.match_data"] || {}
    Rails.logger.warn(
      event: "rack_attack.throttled",
      name: request.env["rack.attack.matched"],
      discriminator: data[:discriminator],
      count: data[:count],
      period: data[:period],
      path: request.path,
      ip: request.ip
    )

    retry_after = data[:period].to_i if data[:period].present?

    [
      429,
      {
        "Content-Type" => "application/json; charset=utf-8",
        "Retry-After" => retry_after.to_s
      }.compact,
      [ THROTTLED_RESPONSE.to_json ]
    ]
  end
end
