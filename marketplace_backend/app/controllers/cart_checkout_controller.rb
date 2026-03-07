class CartCheckoutController < ApplicationController
  wrap_parameters false

  FORBIDDEN_KEYS = %w[id user_id owner_id cart_id].freeze
  ALLOWED_KEYS = %w[payment_method].freeze

  before_action :authenticate_user!

  def create
    return render_invalid_payload unless request.content_mime_type&.json?
    return render_invalid_payload unless valid_payload_shape?

    result = Carts::Finalize.call(user: current_user, params: resource_payload)
    return render_not_found if result.error_code == :not_found
    return render_invalid_payload unless result.success?

    render json: {
      data: {
        cart: Carts::CartSerializer.call(cart: result.cart),
        order_preparation: result.preparation,
      },
    }, status: :ok
  end

  private

  def raw_payload
    payload = request.request_parameters
    return {} unless payload.is_a?(Hash)

    payload
  end

  def resource_payload
    raw_payload["checkout"]
  end

  def valid_payload_shape?
    return false if includes_forbidden_keys?(request.parameters.except("controller", "action", "format"))
    return false unless raw_payload.keys.map(&:to_s) == ["checkout"]
    return false unless resource_payload.is_a?(Hash)

    keys = resource_payload.keys.map(&:to_s)
    return false unless keys.sort == ALLOWED_KEYS.sort

    true
  end

  def includes_forbidden_keys?(obj)
    case obj
    when Hash
      obj.any? do |key, value|
        FORBIDDEN_KEYS.include?(key.to_s) || includes_forbidden_keys?(value)
      end
    when Array
      obj.any? { |value| includes_forbidden_keys?(value) }
    else
      false
    end
  end

  def render_not_found
    render json: { error: "nao encontrado" }, status: :not_found
  end
end
