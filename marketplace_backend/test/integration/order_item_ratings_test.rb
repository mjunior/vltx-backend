require "test_helper"

class OrderItemRatingsTest < ActionDispatch::IntegrationTest
  def create_user(email: "order-item-ratings-buyer@example.com", password: "password123")
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
      title: "Produto Rating Integration",
      description: "Descricao valida para rating integration",
      price: "27.00",
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

  def create_delivered_order_item
    buyer = create_user
    seller = create_user(email: "order-item-ratings-seller@example.com")
    product = create_product_for(seller)
    cart = Cart.create!(user: buyer, status: :active)
    CartItem.create!(cart: cart, product: product, quantity: 1)
    seed_wallet_for(buyer, amount_cents: 100_00)
    checkout = Carts::Finalize.call(user: buyer, params: { payment_method: "wallet" })
    order = Order.find(checkout.order_ids.first)
    Orders::Advance.call(order: order, actor: order.seller)
    Orders::Advance.call(order: order.reload, actor: order.seller)
    Orders::MarkDelivered.call(order: order.reload, actor: order.user)
    [buyer, order.reload, order.order_items.first.reload]
  end

  test "creates rating pair for delivered order item" do
    buyer, order, item = create_delivered_order_item
    token = access_token_for(buyer)

    post "/orders/#{order.id}/items/#{item.id}/rating",
         params: { rating: { score: 5, comment: "Excelente compra" } },
         headers: { "Authorization" => "Bearer #{token}" },
         as: :json

    assert_response :created
    body = JSON.parse(response.body)
    assert body.dig("data", "product_rating_id").present?
    assert body.dig("data", "seller_rating_id").present?
  end

  test "rejects forged identifiers in payload" do
    buyer, order, item = create_delivered_order_item
    token = access_token_for(buyer)

    post "/orders/#{order.id}/items/#{item.id}/rating",
         params: { rating: { score: 5, comment: "Excelente compra" }, seller_id: SecureRandom.uuid },
         headers: { "Authorization" => "Bearer #{token}" },
         as: :json

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
  end

  test "rejects rating another buyers order item" do
    buyer, order, item = create_delivered_order_item
    intruder = create_user(email: "order-item-ratings-intruder@example.com")
    token = access_token_for(intruder)

    post "/orders/#{order.id}/items/#{item.id}/rating",
         params: { rating: { score: 4, comment: "Tentativa indevida" } },
         headers: { "Authorization" => "Bearer #{token}" },
         as: :json

    assert_response :not_found
  end
end
