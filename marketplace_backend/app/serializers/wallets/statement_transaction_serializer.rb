module Wallets
  class StatementTransactionSerializer
    class << self
      def call(transaction:)
        payload = {
          id: transaction.id,
          transaction_type: transaction.transaction_type,
          amount_cents: transaction.amount_cents,
          balance_after_cents: transaction.balance_after_cents,
          reference_type: transaction.reference_type,
          reference_id: transaction.reference_id,
          created_at: transaction.created_at,
        }

        if transaction.reference_type == "checkout_group"
          payload[:checkout_group_id] = transaction.reference_id
          payload[:order_ids] = Array(transaction.metadata["order_ids"])
          payload[:orders_count] = transaction.metadata["orders_count"].to_i
        end

        payload
      end
    end
  end
end
