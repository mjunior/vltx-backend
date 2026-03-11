class Admin::OrdersController < Admin::ApplicationController
  INTERNAL_KEYS = %w[controller action format id status].freeze

  before_action :authenticate_admin!
  before_action :load_order!, only: :show

  def index
    return render_invalid_payload if unsupported_query_keys.present?
    return render_invalid_payload if invalid_status_filter?

    orders = orders_scope.recent_first

    render json: {
      data: {
        orders: orders.map { |order| Orders::OrderSerializer.call(order: order, viewer: current_admin) }
      }
    }, status: :ok
  end

  def show
    render json: {
      data: Orders::OrderSerializer.call(order: @order, viewer: current_admin)
    }, status: :ok
  end

  def approve
    result = AdminOrders::ApproveContestation.call(order_id: params[:id], admin: current_admin)
    return render_not_found if result.error_code == :not_found
    return render_insufficient_funds if result.error_code == :insufficient_funds
    return render_invalid_payload unless result.success?

    render json: {
      data: Orders::OrderSerializer.call(order: result.order, viewer: current_admin)
    }, status: :ok
  end

  def deny
    result = AdminOrders::DenyContestation.call(order_id: params[:id], admin: current_admin)
    return render_not_found if result.error_code == :not_found
    return render_invalid_payload unless result.success?

    render json: {
      data: Orders::OrderSerializer.call(order: result.order, viewer: current_admin)
    }, status: :ok
  end

  private
  def load_order!
    @order = orders_scope.find_by(id: params[:id])
    return render_not_found unless @order
  end

  def orders_scope
    scope = Order.includes(:order_transitions, order_items: [:product_rating, :seller_rating])
    return scope unless status_filter.present?

    scope.where(status: status_filter)
  end

  def unsupported_query_keys
    request.query_parameters.keys - ["status"]
  end

  def invalid_status_filter?
    status_filter.present? && !Order::STATUSES.value?(status_filter.to_s)
  end

  def status_filter
    request.query_parameters["status"]
  end

  def render_not_found
    render json: { error: "nao encontrado" }, status: :not_found
  end

  def render_insufficient_funds
    render json: { error: "saldo insuficiente" }, status: :unprocessable_entity
  end
end
