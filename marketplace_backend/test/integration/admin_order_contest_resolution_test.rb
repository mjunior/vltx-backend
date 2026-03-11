require "test_helper"

class AdminOrderContestResolutionTest < ActionDispatch::IntegrationTest
  THROTTLE_IP = "198.51.100.26".freeze

  def create_user(email:, password: "password123")
    Users::Create.call(email: email, password: password, password_confirmation: password).user
  end

  def create_admin(email: "admin-contest@example.com", password: "password123")
    Admin.create!(email: email, password: password, password_confirmation: password)
  end

  def admin_access_token(admin)
    post "/admin/auth/login", params: { email: admin.email, password: "password123" }, as: :json
    JSON.parse(response.body).dig("data", "access_token")
  end

  def user_access_token(user)
    post "/auth/login", params: { email: user.email, password: "password123" }, as: :json
    JSON.parse(response.body).dig("data", "access_token")
  end

  def create_product_for(user, title: "Produto Contest Admin")
    Products::Create.call(user: user, params: {
      title: title,
      description: "Descricao valida para resolucao admin de contestacao",
      price: "60.00",
      stock_quantity: 4
    }).product
  end

  def create_contested_order
    buyer = create_user(email: "buyer-admin-contest-#{SecureRandom.hex(4)}@example.com")
    seller = create_user(email: "seller-admin-contest-#{SecureRandom.hex(4)}@example.com")
    product = create_product_for(seller, title: "Produto Contest #{SecureRandom.hex(2)}")
    cart = Cart.create!(user: buyer, status: :active)
    CartItem.create!(cart: cart, product: product, quantity: 1)
    Wallet.find_or_create_by!(user: buyer)
    Wallet.find_or_create_by!(user: seller)
    Wallets::Operations::ApplyMovement.call(
      wallet: buyer.wallet,
      transaction_type: :credit,
      trusted_amount_cents: 20_000,
      reference_type: "seed",
      reference_id: SecureRandom.uuid,
      operation_key: "seed-admin-contest-#{buyer.id}"
    )

    result = Carts::Finalize.call(user: buyer, params: { payment_method: "wallet" })
    order = Order.find(result.order_ids.first)
    Orders::Advance.call(order: order, actor: seller)
    Orders::Advance.call(order: order.reload, actor: seller)
    Orders::MarkDelivered.call(order: order.reload, actor: buyer)
    Orders::Contest.call(order: order.reload, actor: buyer)
    order.reload
  end

  test "admin approves contested order with refund" do
    order = create_contested_order
    admin = create_admin
    admin_token = admin_access_token(admin)

    post "/admin/orders/#{order.id}/approve", headers: {
      "Authorization" => "Bearer #{admin_token}"
    }, as: :json

    assert_response :success
    body = JSON.parse(response.body).fetch("data")
    assert_equal "refunded", body.fetch("status")
    assert_equal "admin", body.fetch("actor_role")
    assert_equal "reversed", order.reload.seller_receivable.reload.status
    assert_equal 1, Wallet.find_by!(user: order.user).wallet_transactions.where(transaction_type: :refund, reference_type: "order_contest_resolution", reference_id: order.id).count
    assert_equal 1, Wallet.find_by!(user: order.seller).wallet_transactions.where(transaction_type: :debit, reference_type: "order_contest_resolution", reference_id: order.id).count
  end

  test "admin approval is idempotent after refund" do
    order = create_contested_order
    admin = create_admin(email: "admin-contest-idempotent@example.com")
    admin_token = admin_access_token(admin)

    post "/admin/orders/#{order.id}/approve", headers: {
      "Authorization" => "Bearer #{admin_token}"
    }, as: :json
    assert_response :success

    post "/admin/orders/#{order.id}/approve", headers: {
      "Authorization" => "Bearer #{admin_token}"
    }, as: :json

    assert_response :success
    assert_equal "refunded", JSON.parse(response.body).dig("data", "status")
  end

  test "admin deny returns contested order to delivered" do
    order = create_contested_order
    admin = create_admin(email: "admin-contest-deny@example.com")
    admin_token = admin_access_token(admin)

    post "/admin/orders/#{order.id}/deny", headers: {
      "Authorization" => "Bearer #{admin_token}"
    }, as: :json

    assert_response :success
    assert_equal "delivered", JSON.parse(response.body).dig("data", "status")
    assert_equal "delivered", order.reload.status
    assert_equal 0, Wallet.find_by!(user: order.user).wallet_transactions.where(transaction_type: :refund, reference_type: "order_contest_resolution", reference_id: order.id).count
  end

  test "admin approve keeps insufficient funds error when seller wallet is drained" do
    order = create_contested_order
    seller_wallet = Wallet.find_by!(user: order.seller)
    drain = Wallets::Operations::ApplyMovement.call(
      wallet: seller_wallet,
      transaction_type: :debit,
      trusted_amount_cents: order.subtotal_cents,
      reference_type: "manual_spend",
      reference_id: "spend-#{order.id}",
      operation_key: "manual-spend-admin-contest:#{order.id}",
      metadata: { "source" => "test_spend", "reason" => "drain_wallet" }
    )
    raise "drain failed" unless drain.success?

    admin = create_admin(email: "admin-contest-insufficient@example.com")
    admin_token = admin_access_token(admin)

    post "/admin/orders/#{order.id}/approve", headers: {
      "Authorization" => "Bearer #{admin_token}"
    }, as: :json

    assert_response :unprocessable_entity
    assert_equal "saldo insuficiente", JSON.parse(response.body)["error"]
    assert_equal "contested", order.reload.status
  end

  test "user token cannot approve or deny contest through admin endpoints" do
    order = create_contested_order
    user_token = user_access_token(order.user)

    post "/admin/orders/#{order.id}/approve", headers: {
      "Authorization" => "Bearer #{user_token}"
    }, as: :json

    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]

    post "/admin/orders/#{order.id}/deny", headers: {
      "Authorization" => "Bearer #{user_token}"
    }, as: :json

    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]
  end

  test "approve throttles bursts by authenticated admin" do
    order = create_contested_order
    admin = create_admin(email: "admin-contest-throttle-approve@example.com")
    admin_token = admin_access_token(admin)

    5.times do
      post "/admin/orders/#{order.id}/approve", headers: {
        "Authorization" => "Bearer #{admin_token}",
        "REMOTE_ADDR" => THROTTLE_IP
      }, as: :json
    end

    post "/admin/orders/#{order.id}/approve", headers: {
      "Authorization" => "Bearer #{admin_token}",
      "REMOTE_ADDR" => THROTTLE_IP
    }, as: :json

    assert_response :too_many_requests
    assert_equal "muitas requisicoes", JSON.parse(response.body)["error"]
  end

  test "deny throttles bursts by authenticated admin" do
    order = create_contested_order
    admin = create_admin(email: "admin-contest-throttle-deny@example.com")
    admin_token = admin_access_token(admin)

    5.times do
      post "/admin/orders/#{order.id}/deny", headers: {
        "Authorization" => "Bearer #{admin_token}",
        "REMOTE_ADDR" => THROTTLE_IP
      }, as: :json
    end

    post "/admin/orders/#{order.id}/deny", headers: {
      "Authorization" => "Bearer #{admin_token}",
      "REMOTE_ADDR" => THROTTLE_IP
    }, as: :json

    assert_response :too_many_requests
    assert_equal "muitas requisicoes", JSON.parse(response.body)["error"]
  end
end
