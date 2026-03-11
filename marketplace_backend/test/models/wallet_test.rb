require "test_helper"

class WalletTest < ActiveSupport::TestCase
  def create_user(email: "wallet-model@example.com")
    Users::Create.call(
      email: email,
      password: "password123",
      password_confirmation: "password123"
    ).user
  end

  test "enforces one wallet per user" do
    user = create_user
    Wallet.create!(user: user, current_balance_cents: 0)

    duplicate = Wallet.new(user: user, current_balance_cents: 10)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  test "requires non-negative current balance in cents" do
    user = create_user(email: "wallet-non-negative@example.com")

    wallet = Wallet.new(user: user, current_balance_cents: -1)

    assert_not wallet.valid?
    assert_includes wallet.errors[:current_balance_cents], "must be greater than or equal to 0"
  end

  test "accepts integer current balance in cents" do
    user = create_user(email: "wallet-integer@example.com")

    wallet = Wallet.new(user: user, current_balance_cents: 1_250)

    assert wallet.valid?
  end

  test "grants initial credit when wallet is created" do
    user = create_user(email: "wallet-initial-credit@example.com")

    wallet = Wallet.create!(user: user, current_balance_cents: 0)

    assert_equal 10_00, wallet.reload.current_balance_cents
    assert_equal 1, wallet.wallet_transactions.where(reference_type: Wallet::INITIAL_CREDIT_REFERENCE_TYPE).count
  end

  test "does not duplicate initial credit after wallet updates" do
    user = create_user(email: "wallet-initial-credit-once@example.com")
    wallet = Wallet.create!(user: user, current_balance_cents: 0)

    wallet.touch

    assert_equal 1, wallet.reload.wallet_transactions.where(reference_type: Wallet::INITIAL_CREDIT_REFERENCE_TYPE).count
    assert_equal 10_00, wallet.current_balance_cents
  end
end
