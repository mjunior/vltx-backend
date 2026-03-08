module Wallets
  class BalanceSerializer
    class << self
      def call(wallet:)
        {
          id: wallet.id,
          current_balance_cents: wallet.current_balance_cents,
          created_at: wallet.created_at,
          updated_at: wallet.updated_at,
        }
      end
    end
  end
end
