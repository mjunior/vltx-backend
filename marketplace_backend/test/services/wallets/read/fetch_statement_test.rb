require "test_helper"

module Wallets
  module Read
    class FetchStatementTest < ActiveSupport::TestCase
      def create_user(email: "wallet-read-statement@example.com")
        Users::Create.call(
          email: email,
          password: "password123",
          password_confirmation: "password123"
        ).user
      end

      def append(wallet:, amount_cents:, operation_key:)
        Wallets::Ledger::AppendTransaction.call(
          wallet: wallet,
          transaction_type: :credit,
          amount_cents: amount_cents,
          reference_type: "seed",
          reference_id: operation_key,
          operation_key: operation_key,
          metadata: { "source" => "seed" }
        )
      end

      test "returns only the latest 30 transactions in descending order" do
        user = create_user
        wallet = Wallet.create!(user: user, current_balance_cents: 0)

        35.times do |i|
          result = append(wallet: wallet, amount_cents: i + 1, operation_key: "seed-#{i + 1}")
          assert result.success?
        end

        response = FetchStatement.call(user: user)

        assert response.success?
        assert_equal wallet.id, response.wallet.id
        assert_equal 30, response.transactions.length
        assert_equal "seed-35", response.transactions.first.reference_id
        assert_equal "seed-6", response.transactions.last.reference_id
      end

      test "auto provisions wallet and returns empty statement for new user" do
        user = create_user(email: "wallet-read-empty@example.com")

        response = FetchStatement.call(user: user)

        assert response.success?
        assert response.wallet.persisted?
        assert_equal user.id, response.wallet.user_id
        assert_empty response.transactions
      end

      test "returns invalid payload for invalid user" do
        response = FetchStatement.call(user: nil)

        assert_not response.success?
        assert_equal :invalid_payload, response.error_code
      end
    end
  end
end
