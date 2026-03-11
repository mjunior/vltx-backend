require "test_helper"

class AdminOrdersIndexTest < ActionDispatch::IntegrationTest
  def create_user(email:, password: "password123")
    Users::Create.call(email: email, password: password, password_confirmation: password).user
  end

  def create_admin(email: "admin-orders@example.com", password: "password123")
    Admin.create!(email: email, password: password, password_confirmation: password)
  end

  def user_access_token(user)
    post "/auth/login", params: { email: user.email, password: "password123" }, as: :json
    JSON.parse(response.body).dig("data", "access_token")
  end

  def admin_access_token(admin)
    post "/admin/auth/login", params: { email: admin.email, password: "password123" }, as: :json
    JSON.parse(response.body).dig("data", "access_token")
  end

  def create_product_for(user, title:)
    Products::Create.call(user: user, params: {
      title: title,
      description: "Descricao valida para pedido administrativo #{title}",
      price: "35.00",
      stock_quantity: 10
    }).product
  end

  def create_order(status: :paid, buyer_email: "buyer-admin-orders@example.com", seller_email: "seller-admin-orders@example.com")
    buyer = create_user(email: buyer_email)
    seller = create_user(email: seller_email)
    product = create_product_for(seller, title: "Produto #{status}")
    cart = Cart.create!(user: buyer, status: :active)
    CartItem.create!(cart: cart, product: product, quantity: 1)
    Wallet.find_or_create_by!(user: buyer)
    Wallet.find_or_create_by!(user: seller)
    Wallets::Operations::ApplyMovement.call(
      wallet: buyer.wallet,
      transaction_type: :credit,
      trusted_amount_cents: 10_000,
      reference_type: "seed",
      reference_id: SecureRandom.uuid,
      operation_key: "seed-admin-order-#{status}-#{buyer.id}"
    )

    result = Carts::Finalize.call(user: buyer, params: { payment_method: "wallet" })
    order = Order.find(result.order_ids.first)

    case status.to_sym
    when :confirmed
      Orders::Advance.call(order: order, actor: seller)
      Orders::Advance.call(order: order.reload, actor: seller)
    when :delivered
      Orders::Advance.call(order: order, actor: seller)
      Orders::Advance.call(order: order.reload, actor: seller)
      Orders::MarkDelivered.call(order: order.reload, actor: buyer)
    when :contested
      Orders::Advance.call(order: order, actor: seller)
      Orders::Advance.call(order: order.reload, actor: seller)
      Orders::MarkDelivered.call(order: order.reload, actor: buyer)
      Orders::Contest.call(order: order.reload, actor: buyer)
    when :canceled
      Orders::Cancel.call(order: order, actor: buyer)
    end

    order.reload
  end

  test "admin lists orders across users and statuses" do
    paid_order = create_order(status: :paid, buyer_email: "buyer-paid@example.com", seller_email: "seller-paid@example.com")
    contested_order = create_order(status: :contested, buyer_email: "buyer-contested@example.com", seller_email: "seller-contested@example.com")
    admin = create_admin
    admin_token = admin_access_token(admin)

    get "/admin/orders", headers: { "Authorization" => "Bearer #{admin_token}" }, as: :json

    assert_response :success
    orders = JSON.parse(response.body).dig("data", "orders")
    ids = orders.map { |row| row.fetch("id") }

    assert_includes ids, paid_order.id
    assert_includes ids, contested_order.id
  end

  test "admin filters contested orders by status" do
    contested_order = create_order(status: :contested, buyer_email: "buyer-contested-filter@example.com", seller_email: "seller-contested-filter@example.com")
    create_order(status: :paid, buyer_email: "buyer-paid-filter@example.com", seller_email: "seller-paid-filter@example.com")
    admin = create_admin(email: "filter-admin@example.com")
    admin_token = admin_access_token(admin)

    get "/admin/orders?status=contested", headers: {
      "Authorization" => "Bearer #{admin_token}"
    }, as: :json

    assert_response :success
    orders = JSON.parse(response.body).dig("data", "orders")
    assert_equal [contested_order.id], orders.map { |row| row.fetch("id") }
  end

  test "returns payload invalido for unsupported admin order status filter" do
    admin = create_admin(email: "invalid-filter-admin@example.com")
    admin_token = admin_access_token(admin)

    get "/admin/orders?status=invalid-status", headers: {
      "Authorization" => "Bearer #{admin_token}"
    }, as: :json

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
  end

  test "admin sees global order detail" do
    order = create_order(status: :delivered, buyer_email: "buyer-show@example.com", seller_email: "seller-show@example.com")
    admin = create_admin(email: "show-admin@example.com")
    admin_token = admin_access_token(admin)

    get "/admin/orders/#{order.id}", headers: { "Authorization" => "Bearer #{admin_token}" }, as: :json

    assert_response :success
    body = JSON.parse(response.body).fetch("data")
    assert_equal order.id, body.fetch("id")
    assert_equal order.status, body.fetch("status")
    assert_equal "admin", body.fetch("actor_role")
    assert_equal false, body.dig("available_actions", "can_advance")
  end

  test "user token cannot access admin orders" do
    user = create_user(email: "user-no-admin-orders@example.com")
    user_token = user_access_token(user)

    get "/admin/orders", headers: { "Authorization" => "Bearer #{user_token}" }, as: :json

    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]
  end
end
