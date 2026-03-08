require "test_helper"

class CartCheckoutTest < ActionDispatch::IntegrationTest
  def create_user(email: "cart-checkout@example.com", password: "password123")
    Users::Create.call(
      email: email,
      password: password,
      password_confirmation: password
    ).user
  end

  def create_product_for(user, attrs = {})
    defaults = {
      title: "Produto Checkout",
      description: "Descricao valida para checkout de carrinho",
      price: "90.00",
      stock_quantity: 6,
    }

    Products::Create.call(user: user, params: defaults.merge(attrs)).product
  end

  def access_token_for(user, password: "password123")
    post "/auth/login", params: {
      email: user.email,
      password: password,
    }, as: :json

    JSON.parse(response.body).dig("data", "access_token")
  end

  def create_wallet_for(user, balance_cents:)
    wallet = Wallet.create!(user: user, current_balance_cents: 0)
    return wallet if balance_cents.zero?

    seed = Wallets::Ledger::AppendTransaction.call(
      wallet: wallet,
      transaction_type: :credit,
      amount_cents: balance_cents,
      reference_type: "seed",
      reference_id: "seed-#{user.id}",
      operation_key: "seed-wallet-#{user.id}",
      metadata: { "source" => "test_seed" }
    )
    raise "wallet seed failed" unless seed.success?

    wallet.reload
  end

  test "finalizes active cart with wallet only and returns preparation metadata" do
    buyer = create_user
    seller = create_user(email: "cart-checkout-seller@example.com")
    product = create_product_for(seller)
    cart = Cart.create!(user: buyer, status: :active)
    CartItem.create!(cart: cart, product: product, quantity: 2)
    wallet = create_wallet_for(buyer, balance_cents: 500_00)
    token = access_token_for(buyer)

    post "/cart/checkout", params: {
      checkout: {
        payment_method: "wallet",
      },
    }, headers: {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE" => "application/json",
    }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    preparation = body.dig("data", "order_preparation")

    assert_equal "finished", cart.reload.status
    assert_equal "wallet", preparation["payment_method"]
    assert_equal cart.id, preparation["source_cart_id"]
    assert_equal "180.00", preparation["subtotal"]
    assert_equal 320_00, wallet.reload.current_balance_cents
  end

  test "returns payload invalido for unsupported payment method" do
    buyer = create_user(email: "cart-checkout-wallet-only@example.com")
    seller = create_user(email: "cart-checkout-wallet-only-seller@example.com")
    product = create_product_for(seller)
    cart = Cart.create!(user: buyer, status: :active)
    CartItem.create!(cart: cart, product: product, quantity: 1)
    token = access_token_for(buyer)

    post "/cart/checkout", params: {
      checkout: {
        payment_method: "pix",
      },
    }, headers: {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE" => "application/json",
    }, as: :json

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
    assert_equal "active", cart.reload.status
  end

  test "returns payload invalido when active cart is empty" do
    buyer = create_user(email: "cart-checkout-empty@example.com")
    Cart.create!(user: buyer, status: :active)
    token = access_token_for(buyer)

    post "/cart/checkout", params: {
      checkout: {
        payment_method: "wallet",
      },
    }, headers: {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE" => "application/json",
    }, as: :json

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
  end

  test "returns nao encontrado when user has no active cart" do
    buyer = create_user(email: "cart-checkout-no-active@example.com")
    Cart.create!(user: buyer, status: :finished)
    token = access_token_for(buyer)

    post "/cart/checkout", params: {
      checkout: {
        payment_method: "wallet",
      },
    }, headers: {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE" => "application/json",
    }, as: :json

    assert_response :not_found
    assert_equal "nao encontrado", JSON.parse(response.body)["error"]
  end
end
