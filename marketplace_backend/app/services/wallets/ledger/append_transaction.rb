module Wallets
  module Ledger
    class AppendTransaction
      Result = Struct.new(:success?, :transaction, :error_code, keyword_init: true)
      IDEMPOTENT_FIELDS = %i[wallet_id transaction_type amount_cents reference_type reference_id].freeze

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

          idempotent_hit = find_existing_by_operation_key(wallet_id: locked_wallet.id)
          if idempotent_hit
            return idempotent_success_or_conflict(existing_transaction: idempotent_hit)
          end

          existing_refund = find_existing_refund_by_reference(wallet_id: locked_wallet.id)
          if existing_refund
            return idempotent_success_or_conflict(existing_transaction: existing_refund, ignore_operation_key: true)
          end

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
        conflict_safe_existing
      rescue ActiveRecord::RecordInvalid => e
        duplicate_op_error = e.record.is_a?(WalletTransaction) &&
                             e.record.errors.attribute_names.include?(:operation_key)
        return conflict_safe_existing if duplicate_op_error

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

      def find_existing_by_operation_key(wallet_id:)
        WalletTransaction.find_by(wallet_id: wallet_id, operation_key: @operation_key)
      end

      def find_existing_refund_by_reference(wallet_id:)
        return nil unless @transaction_type == WalletTransaction::TRANSACTION_TYPES[:refund]

        WalletTransaction.find_by(
          wallet_id: wallet_id,
          transaction_type: WalletTransaction::TRANSACTION_TYPES[:refund],
          reference_type: @reference_type,
          reference_id: @reference_id
        )
      end

      def conflict_safe_existing
        existing = find_existing_by_operation_key(wallet_id: @wallet.id)
        return idempotent_success_or_conflict(existing_transaction: existing) if existing

        refund_existing = find_existing_refund_by_reference(wallet_id: @wallet.id)
        return idempotent_success_or_conflict(existing_transaction: refund_existing, ignore_operation_key: true) if refund_existing

        Result.new(success?: false, error_code: :idempotency_conflict)
      end

      def idempotent_success_or_conflict(existing_transaction:, ignore_operation_key: false)
        ignore_metadata = ignore_operation_key
        return Result.new(success?: false, error_code: :idempotency_conflict) unless idempotent_match?(existing_transaction:, ignore_operation_key:, ignore_metadata:)

        Result.new(success?: true, transaction: existing_transaction)
      end

      def idempotent_match?(existing_transaction:, ignore_operation_key: false, ignore_metadata: false)
        return false unless existing_transaction

        IDEMPOTENT_FIELDS.all? { |field| existing_transaction.public_send(field).to_s == expected_value_for(field).to_s } &&
          metadata_matches?(existing_transaction:, ignore_metadata:) &&
          operation_key_matches?(existing_transaction:, ignore_operation_key:)
      end

      def operation_key_matches?(existing_transaction:, ignore_operation_key:)
        return true if ignore_operation_key

        existing_transaction.operation_key.to_s == @operation_key.to_s
      end

      def metadata_matches?(existing_transaction:, ignore_metadata:)
        return true if ignore_metadata

        normalize_hash(existing_transaction.metadata) == normalize_hash(@metadata)
      end

      def normalize_hash(value)
        return {} unless value.is_a?(Hash)

        value.deep_stringify_keys
      end

      def expected_value_for(field)
        case field
        when :wallet_id then @wallet.id
        when :transaction_type then @transaction_type
        when :amount_cents then @amount_cents
        when :reference_type then @reference_type
        when :reference_id then @reference_id
        end
      end
    end
  end
end
