require "test_helper"

class OrdersActionsTest < ActionDispatch::IntegrationTest
  def create_user(email: "orders-actions-buyer@example.com", password: "password123")
    Users::Create.call(
      email: email,
      password: password,
      password_confirmation: password
    ).user
  end

  def access_token_for(user, password: "password123")
    post "/auth/login", params: { email: user.email, password: password }, as: :json
    JSON.parse(response.body).dig("data", "access_token")
  end

  def create_product_for(user, attrs = {})
    defaults = {
      title: "Produto Orders Actions",
      description: "Descricao valida para pedidos",
      price: "55.00",
      stock_quantity: 6
    }

    Products::Create.call(user: user, params: defaults.merge(attrs)).product
  end

  def seed_wallet_for(user, amount_cents:)
    wallet = Wallet.find_or_create_by!(user: user)
    result = Wallets::Ledger::AppendTransaction.call(
      wallet: wallet,
      transaction_type: :credit,
      amount_cents: amount_cents,
      reference_type: "seed",
      reference_id: "seed-#{user.id}",
      operation_key: "seed-#{user.id}",
      metadata: { "source" => "seed" }
    )
    raise "seed failed" unless result.success?
  end

  def create_paid_order
    buyer = create_user
    seller = create_user(email: "orders-actions-seller@example.com")
    product = create_product_for(seller, stock_quantity: 4)
    cart = Cart.create!(user: buyer, status: :active)
    CartItem.create!(cart: cart, product: product, quantity: 1)
    seed_wallet_for(buyer, amount_cents: 200_00)
    checkout = Carts::Finalize.call(user: buyer, params: { payment_method: "wallet" })

    Order.find(checkout.order_ids.first)
  end

  test "lists and shows only participant orders" do
    order = create_paid_order
    token = access_token_for(order.user)

    get "/orders", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :success
    assert_equal [order.id], JSON.parse(response.body).dig("data", "orders").map { |item| item["id"] }

    get "/orders/#{order.id}", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :success
    assert_equal order.id, JSON.parse(response.body).dig("data", "id")
  end

  test "seller advances and buyer delivers through action endpoints" do
    order = create_paid_order
    seller_token = access_token_for(order.seller)
    buyer_token = access_token_for(order.user)

    post "/orders/#{order.id}/advance", headers: { "Authorization" => "Bearer #{seller_token}" }, as: :json
    assert_response :success
    assert_equal "in_separation", JSON.parse(response.body).dig("data", "status")

    post "/orders/#{order.id}/advance", headers: { "Authorization" => "Bearer #{seller_token}" }, as: :json
    assert_response :success
    assert_equal "confirmed", JSON.parse(response.body).dig("data", "status")

    post "/orders/#{order.id}/deliver", headers: { "Authorization" => "Bearer #{buyer_token}" }, as: :json
    assert_response :success
    assert_equal "delivered", JSON.parse(response.body).dig("data", "status")
  end

  test "buyer cancels through action endpoint while paid" do
    order = create_paid_order
    buyer_token = access_token_for(order.user)

    post "/orders/#{order.id}/cancel", headers: { "Authorization" => "Bearer #{buyer_token}" }, as: :json

    assert_response :success
    assert_equal "canceled", JSON.parse(response.body).dig("data", "status")
  end
end
