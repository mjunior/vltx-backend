require "test_helper"

class CartCheckoutOrdersTest < ActionDispatch::IntegrationTest
  def create_user(email: "cart-checkout-orders@example.com", password: "password123")
    Users::Create.call(
      email: email,
      password: password,
      password_confirmation: password
    ).user
  end

  def create_product_for(user, attrs = {})
    defaults = {
      title: "Produto Checkout Orders",
      description: "Descricao valida para checkout com orders reais",
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

  test "checkout returns order ids and summary for mixed seller cart" do
    buyer = create_user
    seller_a = create_user(email: "cart-checkout-orders-seller-a@example.com")
    seller_b = create_user(email: "cart-checkout-orders-seller-b@example.com")
    product_a = create_product_for(seller_a, title: "Produto A", price: "90.00", stock_quantity: 4)
    product_b = create_product_for(seller_b, title: "Produto B", price: "30.00", stock_quantity: 5)
    cart = Cart.create!(user: buyer, status: :active)
    CartItem.create!(cart: cart, product: product_a, quantity: 2)
    CartItem.create!(cart: cart, product: product_b, quantity: 1)
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
    assert_equal 2, Order.where(id: order_ids).count
    assert_equal 2, summary["orders_count"]
    assert_equal 3, summary["total_items"]
    assert_equal "210.00", summary["subtotal"]
    assert_equal "wallet", summary["payment_method"]
    assert_equal 290_00, wallet.reload.current_balance_cents
    assert_equal 2, product_a.reload.stock_quantity
    assert_equal 4, product_b.reload.stock_quantity
  end

  test "checkout fails entirely when one item is out of stock" do
    buyer = create_user(email: "cart-checkout-orders-insufficient@example.com")
    seller_a = create_user(email: "cart-checkout-orders-insufficient-seller-a@example.com")
    seller_b = create_user(email: "cart-checkout-orders-insufficient-seller-b@example.com")
    product_a = create_product_for(seller_a, title: "Produto A", price: "90.00", stock_quantity: 1)
    product_b = create_product_for(seller_b, title: "Produto B", price: "30.00", stock_quantity: 5)
    cart = Cart.create!(user: buyer, status: :active)
    CartItem.create!(cart: cart, product: product_a, quantity: 2)
    CartItem.create!(cart: cart, product: product_b, quantity: 1)
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

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
    assert_equal "active", cart.reload.status
    assert_equal 2, cart.cart_items.reload.count
    assert_equal 500_00, wallet.reload.current_balance_cents
    assert_equal 1, wallet.wallet_transactions.count
    assert_equal 1, product_a.reload.stock_quantity
    assert_equal 5, product_b.reload.stock_quantity
    assert_equal 0, Order.count
  end
end
