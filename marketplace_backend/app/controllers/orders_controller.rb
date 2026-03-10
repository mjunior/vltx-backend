class OrdersController < ApplicationController
  wrap_parameters false

  INTERNAL_KEYS = %w[controller action format id].freeze

  before_action :authenticate_user!
  before_action :load_order!, only: %i[show advance cancel deliver]

  def index
    return render_invalid_payload if unsupported_query_keys.present?

    orders = Order.includes(:order_items, :order_transitions)
                  .where("user_id = :user_id OR seller_id = :user_id", user_id: current_user.id)
                  .recent_first

    render json: {
      data: {
        orders: orders.map { |order| Orders::OrderSerializer.call(order:, viewer: current_user) }
      }
    }, status: :ok
  end

  def show
    render json: {
      data: Orders::OrderSerializer.call(order: @order, viewer: current_user)
    }, status: :ok
  end

  def advance
    return render_invalid_payload if unsupported_mutation_payload?

    result = Orders::Advance.call(order: @order, actor: current_user)
    return render_not_found if result.error_code == :not_found
    return render_invalid_payload unless result.success?

    render json: { data: Orders::OrderSerializer.call(order: result.order, viewer: current_user) }, status: :ok
  end

  def cancel
    return render_invalid_payload if unsupported_mutation_payload?

    result = Orders::Cancel.call(order: @order, actor: current_user)
    return render_not_found if result.error_code == :not_found
    return render_invalid_payload unless result.success?

    render json: { data: Orders::OrderSerializer.call(order: result.order, viewer: current_user) }, status: :ok
  end

  def deliver
    return render_invalid_payload if unsupported_mutation_payload?

    result = Orders::MarkDelivered.call(order: @order, actor: current_user)
    return render_not_found if result.error_code == :not_found
    return render_invalid_payload unless result.success?

    render json: { data: Orders::OrderSerializer.call(order: result.order, viewer: current_user) }, status: :ok
  end

  private

  def load_order!
    @order = Order.includes(:order_items, :order_transitions).find_by(id: params[:id])
    return render_not_found unless @order
    return render_not_found unless [@order.user_id, @order.seller_id].include?(current_user.id)
  end

  def unsupported_query_keys
    params.to_unsafe_h.keys - INTERNAL_KEYS
  end

  def unsupported_mutation_payload?
    params.to_unsafe_h.keys.any? { |key| !INTERNAL_KEYS.include?(key) }
  end

  def render_not_found
    render json: { error: "nao encontrado" }, status: :not_found
  end
end
