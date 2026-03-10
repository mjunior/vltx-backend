class Admin::OrdersController < Admin::ApplicationController
  before_action :authenticate_admin!
  before_action :load_order!, only: :show

  def index
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

  private
  def load_order!
    @order = orders_scope.find_by(id: params[:id])
    return render_not_found unless @order
  end

  def orders_scope
    Order.includes(:order_transitions, order_items: [:product_rating, :seller_rating])
  end

  def render_not_found
    render json: { error: "nao encontrado" }, status: :not_found
  end
end
