class SellerFinanceController < ApplicationController
  wrap_parameters false

  INTERNAL_QUERY_KEYS = %w[controller action format seller_id].freeze

  before_action :authenticate_user!
  before_action :reject_forged_seller_identifier!

  def show
    return render_invalid_payload if unsupported_query_keys.present?

    result = SellerFinance::ReadSummary.call(seller: current_user)
    return render_invalid_payload unless result.success?

    render json: { data: result.summary }, status: :ok
  end

  private

  def reject_forged_seller_identifier!
    return unless params[:seller_id].present?

    render json: { error: "nao encontrado" }, status: :not_found
  end

  def unsupported_query_keys
    params.to_unsafe_h.keys - INTERNAL_QUERY_KEYS
  end
end
