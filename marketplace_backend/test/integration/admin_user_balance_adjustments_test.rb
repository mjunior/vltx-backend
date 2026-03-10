require "test_helper"

class AdminUserBalanceAdjustmentsTest < ActionDispatch::IntegrationTest
  def create_user(email: "admin-balance-user@example.com", password: "password123", active: true)
    user = Users::Create.call(email: email, password: password, password_confirmation: password).user
    user.update!(active: active)
    user
  end

  def create_admin(email: "admin-balance@example.com", password: "password123")
    Admin.create!(email: email, password: password, password_confirmation: password)
  end

  def admin_access_token(admin)
    post "/admin/auth/login", params: { email: admin.email, password: "password123" }, as: :json
    JSON.parse(response.body).dig("data", "access_token")
  end

  test "admin credits user balance and returns updated balance with transaction" do
    user = create_user
    admin = create_admin
    admin_token = admin_access_token(admin)

    post "/admin/users/#{user.id}/balance-adjustments", params: {
      transaction_type: "credit",
      amount_cents: 2500,
      reason: "Ajuste manual"
    }, headers: {
      "Authorization" => "Bearer #{admin_token}",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    assert_response :success
    body = JSON.parse(response.body).fetch("data")
    assert_equal user.id, body.fetch("user_id")
    assert_equal 2500, body.fetch("current_balance_cents")
    assert_equal "credit", body.dig("transaction", "transaction_type")
    assert_equal "admin_adjustment", body.dig("transaction", "reference_type")
    assert_equal "Ajuste manual", body.dig("transaction", "metadata", "reason")
  end

  test "admin debits user balance without making it negative" do
    user = create_user(email: "admin-balance-debit@example.com")
    Wallet.find_or_create_by!(user: user)
    Wallets::Operations::ApplyMovement.call(
      wallet: user.wallet,
      transaction_type: :credit,
      trusted_amount_cents: 4000,
      reference_type: "seed",
      reference_id: SecureRandom.uuid,
      operation_key: "seed-admin-balance-debit-#{user.id}"
    )
    admin = create_admin(email: "admin-balance-debit@example.com")
    admin_token = admin_access_token(admin)

    post "/admin/users/#{user.id}/balance-adjustments", params: {
      transaction_type: "debit",
      amount_cents: 1500,
      reason: "Correcao"
    }, headers: {
      "Authorization" => "Bearer #{admin_token}",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    assert_response :success
    assert_equal 2500, JSON.parse(response.body).dig("data", "current_balance_cents")
    assert_equal 2500, user.wallet.reload.current_balance_cents
  end

  test "returns payload invalido when debit would make balance negative" do
    user = create_user(email: "admin-balance-negative@example.com")
    admin = create_admin(email: "admin-balance-negative@example.com")
    admin_token = admin_access_token(admin)

    post "/admin/users/#{user.id}/balance-adjustments", params: {
      transaction_type: "debit",
      amount_cents: 1,
      reason: "Tentativa invalida"
    }, headers: {
      "Authorization" => "Bearer #{admin_token}",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
  end

  test "returns payload invalido for missing reason" do
    user = create_user(email: "admin-balance-no-reason@example.com")
    admin = create_admin(email: "admin-balance-no-reason@example.com")
    admin_token = admin_access_token(admin)

    post "/admin/users/#{user.id}/balance-adjustments", params: {
      transaction_type: "credit",
      amount_cents: 1000,
      reason: ""
    }, headers: {
      "Authorization" => "Bearer #{admin_token}",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
  end

  test "returns payload invalido for inactive user" do
    user = create_user(email: "admin-balance-inactive@example.com", active: false)
    admin = create_admin(email: "admin-balance-inactive@example.com")
    admin_token = admin_access_token(admin)

    post "/admin/users/#{user.id}/balance-adjustments", params: {
      transaction_type: "credit",
      amount_cents: 1000,
      reason: "Ajuste"
    }, headers: {
      "Authorization" => "Bearer #{admin_token}",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
  end
end
