require "test_helper"

module Wallets
  module Operations
    class ApplyMovementTest < ActiveSupport::TestCase
      def create_user(email: "wallet-operation-service@example.com")
        Users::Create.call(
          email: email,
          password: "password123",
          password_confirmation: "password123"
        ).user
      end

      def create_wallet(email: "wallet-operation-owner@example.com", balance_cents: 0)
        Wallet.create!(user: create_user(email: email), current_balance_cents: balance_cents)
      end

      def apply(wallet:, transaction_type:, trusted_amount_cents:, operation_key:, reference_id: nil, untrusted_amount_cents: nil)
        ApplyMovement.call(
          wallet: wallet,
          transaction_type: transaction_type,
          trusted_amount_cents: trusted_amount_cents,
          reference_type: "order",
          reference_id: reference_id || operation_key,
          operation_key: operation_key,
          metadata: { "order_id" => "ord-#{operation_key}" },
          untrusted_amount_cents: untrusted_amount_cents
        )
      end

      test "applies credit using trusted amount" do
        wallet = create_wallet

        result = apply(wallet: wallet, transaction_type: :credit, trusted_amount_cents: 500, operation_key: "credit-trusted")

        assert result.success?
        assert_equal 500, wallet.reload.current_balance_cents
      end

      test "rejects movement when untrusted amount is provided" do
        wallet = create_wallet(email: "wallet-operation-untrusted@example.com")

        result = apply(
          wallet: wallet,
          transaction_type: :debit,
          trusted_amount_cents: 100,
          operation_key: "debit-untrusted",
          untrusted_amount_cents: 999
        )

        assert_not result.success?
        assert_equal :invalid_payload, result.error_code
        assert_equal 0, wallet.reload.current_balance_cents
        assert_equal 0, wallet.wallet_transactions.count
      end

      test "returns insufficient funds and does not persist side effects" do
        wallet = create_wallet(email: "wallet-operation-insufficient@example.com")
        seed = apply(wallet: wallet, transaction_type: :credit, trusted_amount_cents: 50, operation_key: "insufficient-seed")
        assert seed.success?

        result = apply(wallet: wallet, transaction_type: :debit, trusted_amount_cents: 200, operation_key: "debit-insufficient")

        assert_not result.success?
        assert_equal :insufficient_funds, result.error_code
        assert_equal 50, wallet.reload.current_balance_cents
        assert_equal 1, wallet.wallet_transactions.count
      end

      test "returns duplicate operation for repeated operation key" do
        wallet = create_wallet(email: "wallet-operation-dup@example.com")

        first = apply(wallet: wallet, transaction_type: :credit, trusted_amount_cents: 150, operation_key: "dup-op")
        second = apply(wallet: wallet, transaction_type: :credit, trusted_amount_cents: 150, operation_key: "dup-op")

        assert first.success?
        assert second.success?
        assert_equal first.transaction.id, second.transaction.id
        assert_equal 1, wallet.reload.wallet_transactions.count
      end

      test "returns idempotency conflict for repeated operation key with different payload" do
        wallet = create_wallet(email: "wallet-operation-conflict@example.com")

        first = apply(wallet: wallet, transaction_type: :credit, trusted_amount_cents: 150, operation_key: "conflict-op")
        second = apply(wallet: wallet, transaction_type: :credit, trusted_amount_cents: 250, operation_key: "conflict-op")

        assert first.success?
        assert_not second.success?
        assert_equal :idempotency_conflict, second.error_code
        assert_equal 1, wallet.reload.wallet_transactions.count
      end

      test "returns balance mismatch and corrects materialized value" do
        wallet = create_wallet(email: "wallet-operation-mismatch@example.com", balance_cents: 0)

        WalletTransaction.create!(
          wallet: wallet,
          transaction_type: :credit,
          amount_cents: 300,
          balance_after_cents: 300,
          reference_type: "seed",
          reference_id: "seed-ref",
          operation_key: "seed-op"
        )
        wallet.update!(current_balance_cents: 10)

        result = apply(wallet: wallet, transaction_type: :debit, trusted_amount_cents: 100, operation_key: "mismatch-op")

        assert_not result.success?
        assert_equal :balance_mismatch, result.error_code
        assert_equal 300, wallet.reload.current_balance_cents
        assert_equal 1, wallet.wallet_transactions.count
      end
    end
  end
end
