require "test_helper"

module Wallets
  module Ledger
    class AppendTransactionTest < ActiveSupport::TestCase
      def create_user(email: "wallet-ledger-service@example.com")
        Users::Create.call(
          email: email,
          password: "password123",
          password_confirmation: "password123"
        ).user
      end

      def create_wallet(email: "wallet-ledger-owner@example.com", balance_cents: 0)
        Wallet.create!(user: create_user(email: email), current_balance_cents: balance_cents)
      end

      def append(wallet:, transaction_type:, amount_cents:, operation_key:, reference_id: nil)
        AppendTransaction.call(
          wallet: wallet,
          transaction_type: transaction_type,
          amount_cents: amount_cents,
          reference_type: "order",
          reference_id: reference_id || operation_key,
          operation_key: operation_key,
          metadata: { "order_id" => "ord-#{operation_key}" }
        )
      end

      test "creates credit transaction and updates wallet balance atomically" do
        wallet = create_wallet

        result = append(wallet: wallet, transaction_type: :credit, amount_cents: 350, operation_key: "credit-1")

        assert result.success?
        assert_equal 350, result.transaction.balance_after_cents
        assert_equal 350, wallet.reload.current_balance_cents
      end

      test "applies debit as negative delta and preserves cents" do
        wallet = create_wallet(email: "wallet-ledger-debit@example.com")
        seed = append(wallet: wallet, transaction_type: :credit, amount_cents: 700, operation_key: "debit-seed")
        assert seed.success?

        result = append(wallet: wallet, transaction_type: :debit, amount_cents: 250, operation_key: "debit-1")

        assert result.success?
        assert_equal 450, result.transaction.balance_after_cents
        assert_equal 450, wallet.reload.current_balance_cents
      end

      test "rejects operation that would create negative balance" do
        wallet = create_wallet(email: "wallet-ledger-negative@example.com")
        seed = append(wallet: wallet, transaction_type: :credit, amount_cents: 100, operation_key: "negative-seed")
        assert seed.success?

        result = append(wallet: wallet, transaction_type: :refund, amount_cents: 250, operation_key: "refund-1")

        assert_not result.success?
        assert_equal :insufficient_funds, result.error_code
        assert_equal 1, wallet.wallet_transactions.count
        assert_equal 100, wallet.reload.current_balance_cents
      end

      test "fails closed when ledger and materialized balance diverge" do
        wallet = create_wallet(email: "wallet-ledger-mismatch@example.com", balance_cents: 0)

        WalletTransaction.create!(
          wallet: wallet,
          transaction_type: :credit,
          amount_cents: 500,
          balance_after_cents: 500,
          reference_type: "seed",
          reference_id: "seed-1",
          operation_key: "seed-op-1"
        )
        wallet.update!(current_balance_cents: 25)

        result = append(wallet: wallet, transaction_type: :credit, amount_cents: 100, operation_key: "credit-after-mismatch")

        assert_not result.success?
        assert_equal :balance_mismatch, result.error_code
        assert_equal 1, wallet.reload.wallet_transactions.count
        assert_equal 500, wallet.reload.current_balance_cents
      end

      test "rejects duplicate operation key per wallet" do
        wallet = create_wallet(email: "wallet-ledger-dup@example.com")

        first = append(wallet: wallet, transaction_type: :credit, amount_cents: 100, operation_key: "dup-op")
        second = append(wallet: wallet, transaction_type: :credit, amount_cents: 100, operation_key: "dup-op")

        assert first.success?
        assert_not second.success?
        assert_equal :duplicate_operation, second.error_code
      end

      test "rejects non-integer amount" do
        wallet = create_wallet(email: "wallet-ledger-invalid-amount@example.com")

        result = AppendTransaction.call(
          wallet: wallet,
          transaction_type: :credit,
          amount_cents: "100",
          reference_type: "order",
          reference_id: "ord-invalid",
          operation_key: "invalid-op"
        )

        assert_not result.success?
        assert_equal :invalid_payload, result.error_code
      end
    end
  end
end
