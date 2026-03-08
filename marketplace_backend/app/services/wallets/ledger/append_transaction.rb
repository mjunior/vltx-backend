module Wallets
  module Ledger
    class AppendTransaction
      Result = Struct.new(:success?, :transaction, :error_code, keyword_init: true)

      class << self
        def call(wallet:, transaction_type:, amount_cents:, reference_type:, reference_id:, operation_key:, metadata: {})
          new(
            wallet: wallet,
            transaction_type: transaction_type,
            amount_cents: amount_cents,
            reference_type: reference_type,
            reference_id: reference_id,
            operation_key: operation_key,
            metadata: metadata
          ).call
        end
      end

      def initialize(wallet:, transaction_type:, amount_cents:, reference_type:, reference_id:, operation_key:, metadata: {})
        @wallet = wallet
        @transaction_type = transaction_type.to_s
        @amount_cents = amount_cents
        @reference_type = reference_type
        @reference_id = reference_id
        @operation_key = operation_key
        @metadata = metadata || {}
      end

      def call
        return Result.new(success?: false, error_code: :invalid_payload) unless valid_input?

        created_transaction = nil

        Wallet.transaction do
          locked_wallet = Wallet.lock.find(@wallet.id)

          ledger_last_balance = last_ledger_balance(wallet_id: locked_wallet.id)
          if locked_wallet.current_balance_cents != ledger_last_balance
            locked_wallet.update!(current_balance_cents: ledger_last_balance)
            return Result.new(success?: false, error_code: :balance_mismatch)
          end

          new_balance = locked_wallet.current_balance_cents + signed_delta
          return Result.new(success?: false, error_code: :insufficient_funds) if new_balance.negative?

          created_transaction = WalletTransaction.create!(
            wallet: locked_wallet,
            transaction_type: @transaction_type,
            amount_cents: @amount_cents,
            balance_after_cents: new_balance,
            reference_type: @reference_type,
            reference_id: @reference_id,
            operation_key: @operation_key,
            metadata: @metadata
          )

          locked_wallet.update!(current_balance_cents: new_balance)
        end

        return Result.new(success?: false, error_code: :balance_mismatch) unless created_transaction

        Result.new(success?: true, transaction: created_transaction)
      rescue ActiveRecord::RecordNotUnique
        Result.new(success?: false, error_code: :duplicate_operation)
      rescue ActiveRecord::RecordInvalid => e
        duplicate_op_error = e.record.is_a?(WalletTransaction) &&
                             e.record.errors.attribute_names.include?(:operation_key)
        return Result.new(success?: false, error_code: :duplicate_operation) if duplicate_op_error

        Result.new(success?: false, error_code: :invalid_payload)
      end

      private

      def valid_input?
        return false unless @wallet.is_a?(Wallet)
        return false unless WalletTransaction::TRANSACTION_TYPES.value?(@transaction_type)
        return false unless @amount_cents.is_a?(Integer)
        return false unless @amount_cents.positive?
        return false if @reference_type.blank? || @reference_id.blank? || @operation_key.blank?

        @metadata.is_a?(Hash)
      end

      def last_ledger_balance(wallet_id:)
        WalletTransaction.where(wallet_id: wallet_id).recent_first.limit(1).pick(:balance_after_cents) || 0
      end

      def signed_delta
        return @amount_cents if @transaction_type == WalletTransaction::TRANSACTION_TYPES[:credit]

        -@amount_cents
      end
    end
  end
end
