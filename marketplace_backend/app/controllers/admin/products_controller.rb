class Admin::ProductsController < Admin::ApplicationController
  before_action :authenticate_admin!

  def soft_delete
    result = AdminProducts::SoftDelete.call(product_id: params[:id])
    return render_not_found if result.error_code == :not_found
    return render_invalid_payload unless result.success?

    render json: {
      data: {
        id: result.product.id,
        deleted_at: result.product.deleted_at,
      }
    }, status: :ok
  end

  private

  def render_not_found
    render json: { error: "nao encontrado" }, status: :not_found
  end
end
