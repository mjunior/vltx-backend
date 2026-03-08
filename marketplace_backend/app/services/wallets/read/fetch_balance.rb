module Wallets
  module Read
    class FetchBalance
      Result = Struct.new(:success?, :wallet, :error_code, keyword_init: true)

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
        Result.new(success?: true, wallet: wallet)
      rescue StandardError
        Result.new(success?: false, error_code: :invalid_payload)
      end
    end
  end
end
