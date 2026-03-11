require "test_helper"

class CartCheckoutTest < ActionDispatch::IntegrationTest
  THROTTLE_IP = "198.51.100.20".freeze

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
    wallet = Wallet.find_or_create_by!(user: user)
    delta_cents = balance_cents - wallet.current_balance_cents
    return wallet if delta_cents.zero?

    seed = Wallets::Ledger::AppendTransaction.call(
      wallet: wallet,
      transaction_type: delta_cents.positive? ? :credit : :debit,
      amount_cents: delta_cents.abs,
      reference_type: "seed",
      reference_id: "seed-#{user.id}",
      operation_key: "seed-wallet-#{user.id}",
      metadata: { "source" => "test_seed" }
    )
    raise "wallet seed failed" unless seed.success?

    wallet.reload
  end

  test "finalizes active cart with wallet only and returns order ids plus summary" do
    buyer = create_user
    seller_a = create_user(email: "cart-checkout-seller-a@example.com")
    seller_b = create_user(email: "cart-checkout-seller-b@example.com")
    first_product = create_product_for(seller_a)
    second_product = create_product_for(seller_b, title: "Produto Checkout B", price: "30.00")
    cart = Cart.create!(user: buyer, status: :active)
    CartItem.create!(cart: cart, product: first_product, quantity: 2)
    CartItem.create!(cart: cart, product: second_product, quantity: 1)
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
    order_ids = body.dig("data", "order_ids")
    summary = body.dig("data", "summary")

    assert_equal "finished", cart.reload.status
    assert_equal 0, cart.cart_items.reload.count
    assert_equal 2, order_ids.length
    assert_equal 2, summary["orders_count"]
    assert summary["checkout_group_id"].present?
    assert_equal "wallet", summary["payment_method"]
    assert_equal "210.00", summary["subtotal"]
    assert_equal 290_00, wallet.reload.current_balance_cents
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

  test "checkout throttles bursts by authenticated actor" do
    buyer = create_user(email: "cart-checkout-throttle@example.com")
    seller = create_user(email: "cart-checkout-throttle-seller@example.com")
    product = create_product_for(seller, price: "10.00")
    token = access_token_for(buyer)

    5.times do
      cart = Cart.find_or_create_by!(user: buyer, status: :active)
      CartItem.find_or_create_by!(cart: cart, product: product) { |item| item.quantity = 1 }

      post "/cart/checkout", params: {
        checkout: {
          payment_method: "wallet",
        },
      }, headers: {
        "Authorization" => "Bearer #{token}",
        "CONTENT_TYPE" => "application/json",
        "REMOTE_ADDR" => THROTTLE_IP,
      }, as: :json
    end

    cart = Cart.find_or_create_by!(user: buyer, status: :active)
    CartItem.find_or_create_by!(cart: cart, product: product) { |item| item.quantity = 1 }

    post "/cart/checkout", params: {
      checkout: {
        payment_method: "wallet",
      },
    }, headers: {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE" => "application/json",
      "REMOTE_ADDR" => THROTTLE_IP,
    }, as: :json

    assert_response :too_many_requests
    assert_equal "muitas requisicoes", JSON.parse(response.body)["error"]
  end
end
