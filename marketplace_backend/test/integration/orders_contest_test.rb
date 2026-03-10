require "test_helper"

class OrdersContestTest < ActionDispatch::IntegrationTest
  def create_user(email: "orders-contest-integration-buyer@example.com", password: "password123")
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
      title: "Produto Contest Integration",
      description: "Descricao valida para contest integration",
      price: "42.00",
      stock_quantity: 5
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

  def create_delivered_order
    buyer = create_user
    seller = create_user(email: "orders-contest-integration-seller@example.com")
    product = create_product_for(seller)
    cart = Cart.create!(user: buyer, status: :active)
    CartItem.create!(cart: cart, product: product, quantity: 1)
    seed_wallet_for(buyer, amount_cents: 120_00)
    checkout = Carts::Finalize.call(user: buyer, params: { payment_method: "wallet" })
    order = Order.find(checkout.order_ids.first)
    Orders::Advance.call(order: order, actor: order.seller)
    Orders::Advance.call(order: order.reload, actor: order.seller)
    Orders::MarkDelivered.call(order: order.reload, actor: order.user)
    order.reload
  end

  test "buyer contests delivered order through endpoint" do
    order = create_delivered_order
    buyer_token = access_token_for(order.user)

    post "/orders/#{order.id}/contest", headers: { "Authorization" => "Bearer #{buyer_token}" }, as: :json

    assert_response :success
    assert_equal "contested", JSON.parse(response.body).dig("data", "status")
  end

  test "seller cannot contest" do
    order = create_delivered_order
    seller_token = access_token_for(order.seller)

    post "/orders/#{order.id}/contest", headers: { "Authorization" => "Bearer #{seller_token}" }, as: :json

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
  end
end
