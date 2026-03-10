require "test_helper"

class OrdersActionGuardsTest < ActionDispatch::IntegrationTest
  def create_user(email: "orders-guards-buyer@example.com", password: "password123")
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
      title: "Produto Orders Guards",
      description: "Descricao valida para guards",
      price: "35.00",
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

  def create_paid_order
    buyer = create_user
    seller = create_user(email: "orders-guards-seller@example.com")
    product = create_product_for(seller, stock_quantity: 5)
    cart = Cart.create!(user: buyer, status: :active)
    CartItem.create!(cart: cart, product: product, quantity: 1)
    seed_wallet_for(buyer, amount_cents: 100_00)
    checkout = Carts::Finalize.call(user: buyer, params: { payment_method: "wallet" })

    Order.find(checkout.order_ids.first)
  end

  test "rejects forged payload on action endpoint" do
    order = create_paid_order
    token = access_token_for(order.seller)

    post "/orders/#{order.id}/advance",
         params: { status: "confirmed" },
         headers: { "Authorization" => "Bearer #{token}" },
         as: :json

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
  end

  test "rejects intruder access as not found" do
    order = create_paid_order
    intruder = create_user(email: "orders-guards-intruder@example.com")
    token = access_token_for(intruder)

    post "/orders/#{order.id}/cancel", headers: { "Authorization" => "Bearer #{token}" }, as: :json

    assert_response :not_found
    assert_equal "nao encontrado", JSON.parse(response.body)["error"]
  end

  test "rejects intruder order show as not found" do
    order = create_paid_order
    intruder = create_user(email: "orders-guards-show-intruder@example.com")
    token = access_token_for(intruder)

    get "/orders/#{order.id}", headers: { "Authorization" => "Bearer #{token}" }

    assert_response :not_found
    assert_equal "nao encontrado", JSON.parse(response.body)["error"]
  end

  test "rejects buyer deliver before order is confirmed" do
    order = create_paid_order
    token = access_token_for(order.user)

    post "/orders/#{order.id}/deliver", headers: { "Authorization" => "Bearer #{token}" }, as: :json

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
  end

  test "rejects seller skipping to confirmed after already confirmed" do
    order = create_paid_order
    token = access_token_for(order.seller)
    post "/orders/#{order.id}/advance", headers: { "Authorization" => "Bearer #{token}" }, as: :json
    post "/orders/#{order.id}/advance", headers: { "Authorization" => "Bearer #{token}" }, as: :json

    post "/orders/#{order.id}/advance", headers: { "Authorization" => "Bearer #{token}" }, as: :json

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
  end
end
