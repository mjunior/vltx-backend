class CartsController < ApplicationController
  wrap_parameters false

  FORBIDDEN_KEYS = %w[id user_id owner_id cart_id].freeze

  before_action :authenticate_user!

  def create
    return render_invalid_payload unless request.content_mime_type&.json?
    return render_invalid_payload unless valid_payload_shape?

    result = Carts::FindOrCreateActive.call(user: current_user)
    return render_invalid_payload unless result.success?

    render json: {
      data: {
        cart: Carts::CartSerializer.call(cart: result.cart),
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
    raw_payload["cart"]
  end

  def valid_payload_shape?
    return false if includes_forbidden_keys?(request.parameters.except("controller", "action", "format"))
    return true if raw_payload.empty?

    raw_payload.keys.map(&:to_s) == ["cart"] && resource_payload.is_a?(Hash) && resource_payload.empty?
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
end
