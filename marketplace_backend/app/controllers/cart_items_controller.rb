class CartItemsController < ApplicationController
  wrap_parameters false

  FORBIDDEN_KEYS = %w[id user_id owner_id cart_id].freeze
  CREATE_ALLOWED_KEYS = %w[product_id quantity price].freeze
  UPDATE_ALLOWED_KEYS = %w[quantity price].freeze

  before_action :authenticate_user!

  def create
    return render_invalid_payload unless request.content_mime_type&.json?
    return render_invalid_payload unless valid_payload_shape?(allowed_keys: CREATE_ALLOWED_KEYS, required_keys: %w[product_id quantity])

    result = Carts::AddItem.call(user: current_user, params: resource_payload)
    return render_invalid_payload unless result.success?

    render json: {
      data: {
        cart: Carts::CartSerializer.call(cart: result.cart),
      },
    }, status: :ok
  end

  def update
    return render_invalid_payload unless request.content_mime_type&.json?
    return render_invalid_payload unless valid_payload_shape?(allowed_keys: UPDATE_ALLOWED_KEYS, required_keys: %w[quantity])

    result = Carts::UpdateItem.call(user: current_user, cart_item_id: params[:id], params: resource_payload)
    return render_not_found if result.error_code == :not_found
    return render_invalid_payload unless result.success?

    render json: {
      data: {
        cart: Carts::CartSerializer.call(cart: result.cart),
      },
    }, status: :ok
  end

  def destroy
    result = Carts::RemoveItem.call(user: current_user, cart_item_id: params[:id])
    return render_not_found if result.error_code == :not_found
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
    raw_payload["cart_item"]
  end

  def valid_payload_shape?(allowed_keys:, required_keys:)
    return false if includes_forbidden_keys?(request.parameters.except("controller", "action", "format", "id"))
    return false unless raw_payload.keys.map(&:to_s) == ["cart_item"]
    return false unless resource_payload.is_a?(Hash)

    keys = resource_payload.keys.map(&:to_s)
    return false unless (required_keys - keys).empty?
    return false unless (keys - allowed_keys).empty?

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
