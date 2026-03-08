module Wallets
  module Read
    class FetchStatement
      Result = Struct.new(:success?, :wallet, :transactions, :error_code, keyword_init: true)
      STATEMENT_LIMIT = 30

      class << self
        def call(user:)
          new(user: user).call
        end
      end

      def initialize(user:)
        @user = user
      end

      def call
        return Result.new(success?: false, error_code: :invalid_payload) unless @user.is_a?(User)

        wallet = Wallet.find_or_create_by!(user: @user)
        transactions = wallet.wallet_transactions.recent_first.limit(STATEMENT_LIMIT)

        Result.new(success?: true, wallet: wallet, transactions: transactions)
      rescue StandardError
        Result.new(success?: false, error_code: :invalid_payload)
      end
    end
  end
end
