class ProductsController < ApplicationController
  wrap_parameters false

  CREATE_ALLOWED_KEYS = %w[title description price stock_quantity].freeze
  UPDATE_ALLOWED_KEYS = %w[title description price stock_quantity active].freeze
  FORBIDDEN_KEYS = %w[owner_id user_id].freeze

  before_action :authenticate_user!

  def create
    return render_invalid_payload unless request.content_mime_type&.json?
    return render_invalid_payload unless valid_payload_shape?(allowed_keys: CREATE_ALLOWED_KEYS)

    result = Products::Create.call(user: current_user, params: resource_payload)
    return render_invalid_payload unless result.success?

    render json: Products::PrivateProductSerializer.call(product: result.product), status: :created
  end

  def update
    return render_invalid_payload unless request.content_mime_type&.json?
    return render_invalid_payload unless valid_payload_shape?(allowed_keys: UPDATE_ALLOWED_KEYS)

    result = Products::Update.call(user: current_user, product_id: params[:id], params: resource_payload)
    return render_not_found if result.error_code == :not_found
    return render_invalid_payload unless result.success?

    render json: Products::PrivateProductSerializer.call(product: result.product), status: :ok
  end

  def deactivate
    result = Products::Deactivate.call(user: current_user, product_id: params[:id])
    return render_not_found if result.error_code == :not_found
    return render_invalid_payload unless result.success?

    render json: Products::PrivateProductSerializer.call(product: result.product), status: :ok
  end

  def destroy
    result = Products::SoftDelete.call(user: current_user, product_id: params[:id])
    return render_not_found if result.error_code == :not_found
    return render_invalid_payload unless result.success?

    head :no_content
  end

  private

  def raw_payload
    payload = request.request_parameters
    return {} unless payload.is_a?(Hash)

    payload
  end

  def resource_payload
    raw_payload["product"]
  end

  def valid_payload_shape?(allowed_keys:)
    return false unless raw_payload.keys.map(&:to_s) == ["product"]
    return false unless resource_payload.is_a?(Hash)
    return false unless (resource_payload.keys.map(&:to_s) & FORBIDDEN_KEYS).empty?

    (resource_payload.keys.map(&:to_s) - allowed_keys).empty?
  end

  def render_not_found
    render json: { error: "nao encontrado" }, status: :not_found
  end
end
