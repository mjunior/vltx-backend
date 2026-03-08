class WalletsController < ApplicationController
  wrap_parameters false

  INTERNAL_QUERY_KEYS = %w[controller action format wallet_id].freeze

  before_action :authenticate_user!
  before_action :reject_forged_wallet_identifier!

  def show
    result = Wallets::Read::FetchBalance.call(user: current_user)
    return render_invalid_payload unless result.success?

    render json: {
      data: Wallets::BalanceSerializer.call(wallet: result.wallet),
    }, status: :ok
  end

  def transactions
    return render_invalid_payload if unsupported_query_keys.present?

    result = Wallets::Read::FetchStatement.call(user: current_user)
    return render_invalid_payload unless result.success?

    render json: {
      data: {
        transactions: result.transactions.map { |tx| Wallets::StatementTransactionSerializer.call(transaction: tx) },
      },
    }, status: :ok
  end

  private

  def reject_forged_wallet_identifier!
    return unless params[:wallet_id].present?

    render_not_found
  end

  def unsupported_query_keys
    params.to_unsafe_h.keys - INTERNAL_QUERY_KEYS
  end

  def render_not_found
    render json: { error: "nao encontrado" }, status: :not_found
  end
end
