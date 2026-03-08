module Wallets
  class StatementTransactionSerializer
    class << self
      def call(transaction:)
        {
          id: transaction.id,
          transaction_type: transaction.transaction_type,
          amount_cents: transaction.amount_cents,
          balance_after_cents: transaction.balance_after_cents,
          reference_type: transaction.reference_type,
          reference_id: transaction.reference_id,
          created_at: transaction.created_at,
        }
      end
    end
  end
end
