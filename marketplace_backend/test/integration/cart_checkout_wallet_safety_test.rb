require "test_helper"

class CartCheckoutWalletSafetyTest < ActionDispatch::IntegrationTest
  def create_user(email: "cart-checkout-wallet-safety@example.com", password: "password123")
    Users::Create.call(
      email: email,
      password: password,
      password_confirmation: password
    ).user
  end

  def create_product_for(user, attrs = {})
    defaults = {
      title: "Produto Wallet Safety",
      description: "Descricao valida para testes de seguranca da wallet no checkout",
      price: "110.00",
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

  test "returns payload invalido when checkout payload tries to inject critical amount" do
    buyer = create_user
    seller = create_user(email: "cart-checkout-wallet-safety-seller@example.com")
    product = create_product_for(seller)
    cart = Cart.create!(user: buyer, status: :active)
    CartItem.create!(cart: cart, product: product, quantity: 1)
    wallet = create_wallet_for(buyer, balance_cents: 500_00)
    token = access_token_for(buyer)

    post "/cart/checkout", params: {
      checkout: {
        payment_method: "wallet",
        amount_cents: 1,
      },
    }, headers: {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE" => "application/json",
    }, as: :json

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
    assert_equal "active", cart.reload.status
    assert_equal 500_00, wallet.reload.current_balance_cents
    assert_equal 1, wallet.wallet_transactions.count
  end

  test "returns pagamento recusado and keeps wallet untouched when funds are insufficient" do
    buyer = create_user(email: "cart-checkout-wallet-insufficient@example.com")
    seller = create_user(email: "cart-checkout-wallet-insufficient-seller@example.com")
    product = create_product_for(seller, price: "250.00")
    cart = Cart.create!(user: buyer, status: :active)
    CartItem.create!(cart: cart, product: product, quantity: 1)
    wallet = create_wallet_for(buyer, balance_cents: 100_00)
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
    assert_equal "pagamento recusado", JSON.parse(response.body)["error"]
    assert_equal "active", cart.reload.status
    assert_equal 100_00, wallet.reload.current_balance_cents
    assert_equal 1, wallet.wallet_transactions.count
  end
end
