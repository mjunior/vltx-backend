require "test_helper"

class AdminDashboardTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers

  def create_user(email:, password: "password123", active: true)
    user = Users::Create.call(email: email, password: password, password_confirmation: password).user
    user.update!(active: active)
    user
  end

  def create_admin(email: "admin-dashboard@example.com", password: "password123")
    Admin.create!(email: email, password: password, password_confirmation: password)
  end

  def admin_access_token(admin)
    post "/admin/auth/login", params: { email: admin.email, password: "password123" }, as: :json
    JSON.parse(response.body).dig("data", "access_token")
  end

  def create_product_for(user, title:, price: "35.00")
    Products::Create.call(user: user, params: {
      title: title,
      description: "Descricao valida para dashboard admin #{title}",
      price: price,
      stock_quantity: 10
    }).product
  end

  def create_order(status:, buyer_email:, seller_email:, now:, created_at_offset_days: 0)
    buyer = create_user(email: buyer_email)
    seller = create_user(email: seller_email)
    product = create_product_for(seller, title: "Produto #{status} #{created_at_offset_days}")
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
      operation_key: "seed-admin-dashboard-#{status}-#{buyer.id}-#{created_at_offset_days}"
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

    target_time = now - created_at_offset_days.days
    order.reload.update_columns(created_at: target_time, updated_at: target_time)
    order.reload
  end

  test "admin reads dashboard metrics for the last 30 days only" do
    now = Time.zone.parse("2026-03-10 12:00:00 UTC")

    travel_to(now) do
      active_user = create_user(email: "dashboard-active@example.com")
      create_user(email: "dashboard-inactive@example.com", active: false)
      paid_order = create_order(
        status: :paid,
        buyer_email: "dashboard-paid-buyer@example.com",
        seller_email: "dashboard-paid-seller@example.com",
        now: now,
        created_at_offset_days: 1
      )
      delivered_order = create_order(
        status: :delivered,
        buyer_email: "dashboard-delivered-buyer@example.com",
        seller_email: "dashboard-delivered-seller@example.com",
        now: now,
        created_at_offset_days: 10
      )
      create_order(
        status: :paid,
        buyer_email: "dashboard-old-buyer@example.com",
        seller_email: "dashboard-old-seller@example.com",
        now: now,
        created_at_offset_days: 40
      )

      admin = create_admin
      admin_token = admin_access_token(admin)

      get "/admin/dashboard", headers: {
        "Authorization" => "Bearer #{admin_token}"
      }, as: :json

      assert_response :success
      body = JSON.parse(response.body).fetch("data")

      assert_equal 30, body.fetch("window_days")
      assert_equal User.count, body.fetch("total_users")
      assert_equal User.active_only.count, body.fetch("active_users")
      assert_equal 2, body.fetch("total_orders")
      assert_equal paid_order.subtotal_cents + delivered_order.subtotal_cents, body.fetch("gross_volume_cents")

      orders_by_status = body.fetch("orders_by_status")
      assert_equal Order::STATUSES.values.sort, orders_by_status.keys.sort
      assert_equal 1, orders_by_status.fetch("paid")
      assert_equal 1, orders_by_status.fetch("delivered")
      assert_equal 0, orders_by_status.fetch("canceled")
      assert_equal 0, orders_by_status.fetch("contested")
      assert body.fetch("starts_at").present?
      assert body.fetch("ends_at").present?

      assert active_user.active?
    end
  end

  test "dashboard returns all order statuses with zero when there are no recent orders" do
    now = Time.zone.parse("2026-03-10 12:00:00 UTC")

    travel_to(now) do
      create_user(email: "dashboard-no-orders@example.com")
      admin = create_admin(email: "dashboard-no-orders-admin@example.com")
      admin_token = admin_access_token(admin)

      get "/admin/dashboard", headers: {
        "Authorization" => "Bearer #{admin_token}"
      }, as: :json

      assert_response :success
      orders_by_status = JSON.parse(response.body).dig("data", "orders_by_status")

      assert_equal Order::STATUSES.values.sort, orders_by_status.keys.sort
      assert orders_by_status.values.all?(&:zero?)
    end
  end
end
