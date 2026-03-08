require "test_helper"

class WalletAuthorizationTest < ActionDispatch::IntegrationTest
  def create_user(email: "wallet-authz@example.com", password: "password123")
    Users::Create.call(
      email: email,
      password: password,
      password_confirmation: password
    ).user
  end

  def access_token_for(user, password: "password123")
    post "/auth/login", params: {
      email: user.email,
      password: password,
    }, as: :json

    JSON.parse(response.body).dig("data", "access_token")
  end

  def seed_wallet_transactions_for(user, count:)
    wallet = Wallet.find_or_create_by!(user: user)

    count.times do |i|
      result = Wallets::Ledger::AppendTransaction.call(
        wallet: wallet,
        transaction_type: :credit,
        amount_cents: i + 1,
        reference_type: "seed",
        reference_id: "seed-#{i + 1}",
        operation_key: "seed-wallet-#{user.id}-#{i + 1}",
        metadata: { "source" => "wallet_authz_test" }
      )
      raise "wallet seed failed" unless result.success?
    end

    wallet.reload
  end

  test "returns token invalido when wallet endpoints are called without token" do
    get "/wallet"

    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]
  end

  test "returns own wallet balance and auto provisions when wallet does not exist" do
    user = create_user(email: "wallet-authz-autoprovision@example.com")
    token = access_token_for(user)

    get "/wallet", headers: {
      "Authorization" => "Bearer #{token}",
    }

    assert_response :success
    data = JSON.parse(response.body).fetch("data")
    assert_equal 0, data.fetch("current_balance_cents")
    assert_equal user.id, Wallet.find(data.fetch("id")).user_id
  end

  test "returns only the latest 30 transactions with allowed fields" do
    user = create_user(email: "wallet-authz-statement@example.com")
    token = access_token_for(user)
    seed_wallet_transactions_for(user, count: 35)

    get "/wallet/transactions", headers: {
      "Authorization" => "Bearer #{token}",
    }

    assert_response :success
    transactions = JSON.parse(response.body).dig("data", "transactions")
    assert_equal 30, transactions.length
    assert_equal "seed-35", transactions.first.fetch("reference_id")
    assert_equal "seed-6", transactions.last.fetch("reference_id")

    sample = transactions.first
    assert sample.key?("reference_type")
    assert sample.key?("reference_id")
    assert_not sample.key?("operation_key")
    assert_not sample.key?("metadata")
  end

  test "returns nao encontrado on forged wallet identifier" do
    owner = create_user(email: "wallet-authz-owner@example.com")
    intruder = create_user(email: "wallet-authz-intruder@example.com")
    token = access_token_for(intruder)
    owner_wallet = seed_wallet_transactions_for(owner, count: 1)

    get "/wallet/transactions", params: {
      wallet_id: owner_wallet.id,
    }, headers: {
      "Authorization" => "Bearer #{token}",
    }

    assert_response :not_found
    assert_equal "nao encontrado", JSON.parse(response.body)["error"]
  end

  test "returns payload invalido for unsupported query params on statement" do
    user = create_user(email: "wallet-authz-invalid-query@example.com")
    token = access_token_for(user)

    get "/wallet/transactions", params: {
      limit: 5,
    }, headers: {
      "Authorization" => "Bearer #{token}",
    }

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
  end

  test "ignores ownership spoofing attempts and still returns own wallet on /wallet" do
    owner = create_user(email: "wallet-authz-owner-show@example.com")
    intruder = create_user(email: "wallet-authz-intruder-show@example.com")
    seed_wallet_transactions_for(owner, count: 3)
    intruder_wallet = seed_wallet_transactions_for(intruder, count: 1)
    token = access_token_for(intruder)

    get "/wallet", headers: {
      "Authorization" => "Bearer #{token}",
    }

    assert_response :success
    data = JSON.parse(response.body).fetch("data")
    assert_equal intruder_wallet.id, data.fetch("id")
  end
end
