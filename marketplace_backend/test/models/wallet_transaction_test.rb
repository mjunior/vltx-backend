require "test_helper"

class WalletTransactionTest < ActiveSupport::TestCase
  def create_user(email: "wallet-tx-model@example.com")
    Users::Create.call(
      email: email,
      password: "password123",
      password_confirmation: "password123"
    ).user
  end

  def create_wallet(email: "wallet-tx-owner@example.com", balance_cents: 0)
    Wallet.create!(user: create_user(email: email), current_balance_cents: balance_cents)
  end

  test "accepts only allowed transaction types" do
    wallet = create_wallet

    tx = WalletTransaction.new(
      wallet: wallet,
      transaction_type: "invalid",
      amount_cents: 100,
      balance_after_cents: 100,
      reference_type: "seed",
      reference_id: "seed-1",
      operation_key: "op-1"
    )

    assert_not tx.valid?
    assert_includes tx.errors[:transaction_type], "is not included in the list"
  end

  test "requires positive integer amount in cents" do
    wallet = create_wallet(email: "wallet-tx-amount@example.com")

    tx = WalletTransaction.new(
      wallet: wallet,
      transaction_type: :credit,
      amount_cents: 0,
      balance_after_cents: 0,
      reference_type: "seed",
      reference_id: "seed-2",
      operation_key: "op-2"
    )

    assert_not tx.valid?
    assert_includes tx.errors[:amount_cents], "must be greater than 0"
  end

  test "requires non-negative balance_after_cents" do
    wallet = create_wallet(email: "wallet-tx-balance-after@example.com")

    tx = WalletTransaction.new(
      wallet: wallet,
      transaction_type: :credit,
      amount_cents: 10,
      balance_after_cents: -1,
      reference_type: "seed",
      reference_id: "seed-3",
      operation_key: "op-3"
    )

    assert_not tx.valid?
    assert_includes tx.errors[:balance_after_cents], "must be greater than or equal to 0"
  end

  test "enforces operation key uniqueness per wallet" do
    wallet = create_wallet(email: "wallet-tx-uniq-a@example.com")

    WalletTransaction.create!(
      wallet: wallet,
      transaction_type: :credit,
      amount_cents: 100,
      balance_after_cents: 100,
      reference_type: "order",
      reference_id: "ord-1",
      operation_key: "same-op"
    )

    duplicate = WalletTransaction.new(
      wallet: wallet,
      transaction_type: :credit,
      amount_cents: 200,
      balance_after_cents: 300,
      reference_type: "order",
      reference_id: "ord-2",
      operation_key: "same-op"
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:operation_key], "has already been taken"

    other_wallet = create_wallet(email: "wallet-tx-uniq-b@example.com")
    allowed = WalletTransaction.new(
      wallet: other_wallet,
      transaction_type: :credit,
      amount_cents: 50,
      balance_after_cents: 50,
      reference_type: "order",
      reference_id: "ord-3",
      operation_key: "same-op"
    )

    assert allowed.valid?
  end

  test "rejects metadata keys outside whitelist" do
    wallet = create_wallet(email: "wallet-tx-meta@example.com")

    tx = WalletTransaction.new(
      wallet: wallet,
      transaction_type: :credit,
      amount_cents: 100,
      balance_after_cents: 100,
      reference_type: "order",
      reference_id: "ord-meta",
      operation_key: "op-meta",
      metadata: { "order_id" => "ord-meta", "evil_key" => true }
    )

    assert_not tx.valid?
    assert_match(/unsupported keys/i, tx.errors[:metadata].first)
  end

  test "blocks updates and deletes to enforce append-only ledger" do
    wallet = create_wallet(email: "wallet-tx-append-only@example.com")

    tx = WalletTransaction.create!(
      wallet: wallet,
      transaction_type: :credit,
      amount_cents: 100,
      balance_after_cents: 100,
      reference_type: "seed",
      reference_id: "seed-append",
      operation_key: "append-op"
    )

    assert_raises(ActiveRecord::ReadOnlyRecord) do
      tx.update!(amount_cents: 200)
    end

    assert_raises(ActiveRecord::ReadOnlyRecord) do
      tx.destroy!
    end
  end
end
