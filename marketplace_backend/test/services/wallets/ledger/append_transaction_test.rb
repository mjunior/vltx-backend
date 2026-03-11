require "test_helper"
require "concurrent"

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
        wallet = Wallet.create!(user: create_user(email: email), current_balance_cents: 0)
        delta_cents = balance_cents - wallet.current_balance_cents
        return wallet if delta_cents.zero?

        result = AppendTransaction.call(
          wallet: wallet,
          transaction_type: delta_cents.positive? ? :credit : :debit,
          amount_cents: delta_cents.abs,
          reference_type: "seed",
          reference_id: "seed-balance-#{wallet.id}",
          operation_key: "seed-balance-#{wallet.id}",
          metadata: { "source" => "test_seed" }
        )
        raise "wallet seed failed" unless result.success?

        wallet.reload
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

      test "applies refund as positive delta and increases balance" do
        wallet = create_wallet(email: "wallet-ledger-negative@example.com")
        seed = append(wallet: wallet, transaction_type: :credit, amount_cents: 100, operation_key: "negative-seed")
        assert seed.success?

        result = append(wallet: wallet, transaction_type: :refund, amount_cents: 250, operation_key: "refund-1")

        assert result.success?
        assert_equal 350, result.transaction.balance_after_cents
        assert_equal 350, wallet.reload.current_balance_cents
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
        assert_equal 3, wallet.reload.wallet_transactions.count
        assert_equal 500, wallet.reload.current_balance_cents
      end

      test "rejects duplicate operation key per wallet" do
        wallet = create_wallet(email: "wallet-ledger-dup@example.com")

        first = append(wallet: wallet, transaction_type: :credit, amount_cents: 100, operation_key: "dup-op")
        second = append(wallet: wallet, transaction_type: :credit, amount_cents: 100, operation_key: "dup-op")

        assert first.success?
        assert second.success?
        assert_equal first.transaction.id, second.transaction.id
        assert_equal 3, wallet.reload.wallet_transactions.count
      end

      test "fails with idempotency conflict when operation key repeats with different payload" do
        wallet = create_wallet(email: "wallet-ledger-conflict@example.com")

        first = append(wallet: wallet, transaction_type: :credit, amount_cents: 100, operation_key: "conflict-op")
        second = append(wallet: wallet, transaction_type: :credit, amount_cents: 200, operation_key: "conflict-op")

        assert first.success?
        assert_not second.success?
        assert_equal :idempotency_conflict, second.error_code
        assert_equal 3, wallet.reload.wallet_transactions.count
      end

      test "deduplicates refund by reference and returns existing transaction" do
        wallet = create_wallet(email: "wallet-ledger-refund-dedup@example.com")
        seed = append(wallet: wallet, transaction_type: :credit, amount_cents: 400, operation_key: "refund-seed")
        assert seed.success?

        first = append(
          wallet: wallet,
          transaction_type: :refund,
          amount_cents: 100,
          operation_key: "refund-op-1",
          reference_id: "order-rf-1"
        )
        second = append(
          wallet: wallet,
          transaction_type: :refund,
          amount_cents: 100,
          operation_key: "refund-op-2",
          reference_id: "order-rf-1"
        )

        assert first.success?
        assert second.success?
        assert_equal first.transaction.id, second.transaction.id
        assert_equal 4, wallet.reload.wallet_transactions.count
      end

      test "returns idempotency conflict for refund duplicate reference with different amount" do
        wallet = create_wallet(email: "wallet-ledger-refund-conflict@example.com")
        seed = append(wallet: wallet, transaction_type: :credit, amount_cents: 400, operation_key: "refund-conflict-seed")
        assert seed.success?

        first = append(
          wallet: wallet,
          transaction_type: :refund,
          amount_cents: 100,
          operation_key: "refund-conflict-op-1",
          reference_id: "order-rf-conflict-1"
        )
        second = append(
          wallet: wallet,
          transaction_type: :refund,
          amount_cents: 80,
          operation_key: "refund-conflict-op-2",
          reference_id: "order-rf-conflict-1"
        )

        assert first.success?
        assert_not second.success?
        assert_equal :idempotency_conflict, second.error_code
        assert_equal 4, wallet.reload.wallet_transactions.count
      end

      test "keeps at most one effective insert for concurrent identical operation keys" do
        wallet = create_wallet(email: "wallet-ledger-concurrent-op@example.com")
        barrier = Concurrent::CyclicBarrier.new(2)
        results = Array.new(2)

        threads = 2.times.map do |idx|
          Thread.new do
            ActiveRecord::Base.connection_pool.with_connection do
              barrier.wait
              results[idx] = append(
                wallet: wallet,
                transaction_type: :credit,
                amount_cents: 90,
                operation_key: "race-op-1"
              )
            end
          end
        end
        threads.each(&:join)

        assert results.all?(&:success?)
        assert_equal results.first.transaction.id, results.second.transaction.id
        assert_equal 1, wallet.reload.wallet_transactions.where(operation_key: "race-op-1").count
      end

      test "keeps at most one effective refund insert for concurrent duplicate references" do
        wallet = create_wallet(email: "wallet-ledger-concurrent-refund@example.com")
        seed = append(wallet: wallet, transaction_type: :credit, amount_cents: 500, operation_key: "refund-race-seed")
        assert seed.success?

        barrier = Concurrent::CyclicBarrier.new(2)
        results = Array.new(2)

        threads = 2.times.map do |idx|
          Thread.new do
            ActiveRecord::Base.connection_pool.with_connection do
              barrier.wait
              results[idx] = append(
                wallet: wallet,
                transaction_type: :refund,
                amount_cents: 120,
                operation_key: "race-refund-#{idx + 1}",
                reference_id: "order-race-refund-1"
              )
            end
          end
        end
        threads.each(&:join)

        assert results.all?(&:success?)
        assert_equal results.first.transaction.id, results.second.transaction.id
        assert_equal 1, wallet.reload.wallet_transactions.where(transaction_type: :refund, reference_id: "order-race-refund-1").count
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
