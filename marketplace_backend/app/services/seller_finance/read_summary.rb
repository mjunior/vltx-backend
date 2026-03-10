module SellerFinance
  class ReadSummary
    Result = Struct.new(:success?, :summary, :error_code, keyword_init: true)

    class << self
      def call(seller:)
        new(seller: seller).call
      end
    end

    def initialize(seller:)
      @seller = seller
    end

    def call
      return Result.new(success?: false, error_code: :invalid_payload) unless @seller.is_a?(User)

      pending_receivables = SellerReceivable.includes(:order, :buyer)
                                            .where(seller_id: @seller.id, status: SellerReceivable::STATUSES[:pending])
                                            .recent_first
      credited_transactions = credited_wallet_transactions
      credited_orders = Order.where(id: credited_transactions.pluck(:reference_id))
                             .index_by { |order| order.id.to_s }

      pending_total_cents = pending_receivables.sum(&:amount_cents)
      credited_total_cents = credited_transactions.sum(&:amount_cents)

      Result.new(
        success?: true,
        summary: {
          seller_id: @seller.id,
          pending_total_cents: pending_total_cents,
          pending_total: cents_to_decimal_string(pending_total_cents),
          credited_total_cents: credited_total_cents,
          credited_total: cents_to_decimal_string(credited_total_cents),
          pending_receivables: pending_receivables.map { |receivable| serialize_receivable(receivable) },
          transaction_history: credited_transactions.map { |transaction| serialize_transaction(transaction, credited_orders[transaction.reference_id.to_s]) }
        }
      )
    rescue StandardError
      Result.new(success?: false, error_code: :invalid_payload)
    end

    private

    def credited_wallet_transactions
      wallet = Wallet.find_by(user_id: @seller.id)
      return WalletTransaction.none unless wallet

      wallet.wallet_transactions
            .where(transaction_type: :credit, reference_type: "order")
            .recent_first
    end

    def serialize_receivable(receivable)
      {
        id: receivable.id,
        order_id: receivable.order_id,
        buyer_id: receivable.buyer_id,
        amount_cents: receivable.amount_cents,
        amount: cents_to_decimal_string(receivable.amount_cents),
        status: receivable.status,
        order_status: receivable.order.status,
        created_at: receivable.created_at
      }
    end

    def serialize_transaction(transaction, order)
      {
        id: transaction.id,
        order_id: transaction.reference_id,
        amount_cents: transaction.amount_cents,
        amount: cents_to_decimal_string(transaction.amount_cents),
        transaction_type: transaction.transaction_type,
        created_at: transaction.created_at,
        order_status: order&.status
      }
    end

    def cents_to_decimal_string(cents)
      format("%.2f", cents.to_i / 100.0)
    end
  end
end
