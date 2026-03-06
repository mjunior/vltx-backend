class ProductsController < ApplicationController
  wrap_parameters false

  ALLOWED_KEYS = %w[title description price stock_quantity].freeze
  FORBIDDEN_KEYS = %w[owner_id user_id].freeze

  before_action :authenticate_user!

  def create
    return render_invalid_payload unless request.content_mime_type&.json?
    return render_invalid_payload unless valid_payload_shape?

    result = Products::Create.call(user: current_user, params: product_payload)
    return render_invalid_payload unless result.success?

    render json: Products::PrivateProductSerializer.call(product: result.product), status: :created
  end

  private

  def raw_payload
    payload = request.request_parameters
    return {} unless payload.is_a?(Hash)

    payload
  end

  def product_payload
    raw_payload["product"]
  end

  def valid_payload_shape?
    return false unless raw_payload.keys.map(&:to_s) == ["product"]
    return false unless product_payload.is_a?(Hash)
    return false unless (product_payload.keys.map(&:to_s) & FORBIDDEN_KEYS).empty?

    (product_payload.keys.map(&:to_s) - ALLOWED_KEYS).empty?
  end
end
