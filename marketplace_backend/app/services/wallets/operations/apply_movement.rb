module Wallets
  module Operations
    class ApplyMovement
      Result = Struct.new(:success?, :transaction, :error_code, keyword_init: true)

      class << self
        def call(wallet:, transaction_type:, trusted_amount_cents:, reference_type:, reference_id:, operation_key:, metadata: {}, untrusted_amount_cents: nil)
          new(
            wallet: wallet,
            transaction_type: transaction_type,
            trusted_amount_cents: trusted_amount_cents,
            reference_type: reference_type,
            reference_id: reference_id,
            operation_key: operation_key,
            metadata: metadata,
            untrusted_amount_cents: untrusted_amount_cents
          ).call
        end
      end

      def initialize(wallet:, transaction_type:, trusted_amount_cents:, reference_type:, reference_id:, operation_key:, metadata: {}, untrusted_amount_cents: nil)
        @wallet = wallet
        @transaction_type = transaction_type
        @trusted_amount_cents = trusted_amount_cents
        @reference_type = reference_type
        @reference_id = reference_id
        @operation_key = operation_key
        @metadata = metadata || {}
        @untrusted_amount_cents = untrusted_amount_cents
      end

      def call
        return Result.new(success?: false, error_code: :invalid_payload) unless valid_input?

        ledger_result = Wallets::Ledger::AppendTransaction.call(
          wallet: @wallet,
          transaction_type: @transaction_type,
          amount_cents: @trusted_amount_cents,
          reference_type: @reference_type,
          reference_id: @reference_id,
          operation_key: @operation_key,
          metadata: @metadata
        )

        return Result.new(success?: false, error_code: ledger_result.error_code) unless ledger_result.success?

        Result.new(success?: true, transaction: ledger_result.transaction)
      end

      private

      def valid_input?
        return false unless @wallet.is_a?(Wallet)
        return false unless @trusted_amount_cents.is_a?(Integer)
        return false unless @trusted_amount_cents.positive?
        return false unless @reference_type.present? && @reference_id.present? && @operation_key.present?
        return false unless @metadata.is_a?(Hash)

        @untrusted_amount_cents.nil?
      end
    end
  end
end
