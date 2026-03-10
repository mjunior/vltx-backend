class OrderItemRatingsController < ApplicationController
  wrap_parameters false

  FORBIDDEN_KEYS = %w[id order_id buyer_id seller_id product_id user_id].freeze
  ALLOWED_KEYS = %w[score comment].freeze

  before_action :authenticate_user!
  before_action :load_order_item!

  def create
    return render_invalid_payload unless request.content_mime_type&.json?
    return render_invalid_payload unless valid_payload_shape?

    result = Ratings::CreateForOrderItem.call(
      order_item: @order_item,
      buyer: current_user,
      score: rating_payload["score"],
      comment: rating_payload["comment"]
    )

    return render_not_found if result.error_code == :not_found
    return render_invalid_payload unless result.success?

    render json: {
      data: {
        product_rating_id: result.product_rating.id,
        seller_rating_id: result.seller_rating.id
      }
    }, status: :created
  end

  private

  def raw_payload
    payload = request.request_parameters
    return {} unless payload.is_a?(Hash)

    payload
  end

  def rating_payload
    raw_payload["rating"]
  end

  def load_order_item!
    order = Order.find_by(id: params[:order_id], user_id: current_user.id)
    return render_not_found unless order

    @order_item = order.order_items.find_by(id: params[:id])
    render_not_found unless @order_item
  end

  def valid_payload_shape?
    return false if includes_forbidden_keys?(request.parameters.except("controller", "action", "format", "order_id", "id"))
    return false unless raw_payload.keys.map(&:to_s) == ["rating"]
    return false unless rating_payload.is_a?(Hash)

    rating_payload.keys.map(&:to_s).sort == ALLOWED_KEYS.sort
  end

  def includes_forbidden_keys?(obj)
    case obj
    when Hash
      obj.any? { |key, value| FORBIDDEN_KEYS.include?(key.to_s) || includes_forbidden_keys?(value) }
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
