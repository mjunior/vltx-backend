require "test_helper"

class SellerFinanceTest < ActionDispatch::IntegrationTest
  def create_user(email: "seller-finance-integration-buyer@example.com", password: "password123")
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
      title: "Produto Seller Finance Integration",
      description: "Descricao valida para seller finance integration",
      price: "32.00",
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

  def create_paid_order_for(seller:, buyer:)
    product = create_product_for(seller)
    cart = Cart.create!(user: buyer, status: :active)
    CartItem.create!(cart: cart, product: product, quantity: 1)
    seed_wallet_for(buyer, amount_cents: 100_00)
    checkout = Carts::Finalize.call(user: buyer, params: { payment_method: "wallet" })
    Order.find(checkout.order_ids.first)
  end

  test "shows pending seller finance summary for authenticated seller" do
    seller = create_user(email: "seller-finance-integration-seller@example.com")
    buyer = create_user
    order = create_paid_order_for(seller: seller, buyer: buyer)
    token = access_token_for(seller)

    get "/seller/finance", headers: { "Authorization" => "Bearer #{token}" }

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal seller.id, body.dig("data", "seller_id")
    assert_equal order.id, body.dig("data", "pending_receivables", 0, "order_id")
  end

  test "rejects forged seller identifier query" do
    seller = create_user(email: "seller-finance-integration-forged@example.com")
    token = access_token_for(seller)

    get "/seller/finance", params: { seller_id: SecureRandom.uuid }, headers: { "Authorization" => "Bearer #{token}" }

    assert_response :not_found
    assert_equal "nao encontrado", JSON.parse(response.body)["error"]
  end
end
