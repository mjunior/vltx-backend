class Admin::UserBalanceAdjustmentsController < Admin::ApplicationController
  wrap_parameters false

  before_action :authenticate_admin!

  def create
    return render_invalid_payload unless request.content_mime_type&.json?
    return render_invalid_payload unless unknown_keys.empty?

    result = AdminUsers::ApplyBalanceAdjustment.call(
      user_id: params[:id],
      admin: current_admin,
      params: balance_adjustment_params.to_h
    )

    return render_not_found if result.error_code == :not_found
    return render_invalid_payload unless result.success?

    render json: {
      data: {
        user_id: result.user.id,
        current_balance_cents: result.wallet.current_balance_cents,
        transaction: Admin::Wallets::TransactionSerializer.call(transaction: result.transaction),
      }
    }, status: :ok
  end

  private

  def balance_adjustment_params
    ActionController::Parameters.new(raw_payload).permit(:transaction_type, :amount_cents, :reason)
  end

  def raw_payload
    payload = request.request_parameters
    return {} unless payload.is_a?(Hash)

    payload
  end

  def unknown_keys
    raw_payload.keys.map(&:to_s) - %w[transaction_type amount_cents reason]
  end
end
