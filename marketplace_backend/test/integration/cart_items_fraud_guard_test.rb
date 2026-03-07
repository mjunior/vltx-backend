require "test_helper"

class CartItemsFraudGuardTest < ActionDispatch::IntegrationTest
  def create_user(email: "cart-items-fraud@example.com", password: "password123")
    Users::Create.call(email: email, password: password, password_confirmation: password).user
  end

  def create_product_for(user, attrs = {})
    Products::Create.call(user: user, params: {
      title: "Produto Fraud Guard",
      description: "Descricao valida para testes de fraude em cart item",
      price: "60.00",
      stock_quantity: 3,
    }.merge(attrs)).product
  end

  def access_token_for(user, password: "password123")
    post "/auth/login", params: { email: user.email, password: password }, as: :json
    JSON.parse(response.body).dig("data", "access_token")
  end

  test "ignores forged price field from frontend" do
    buyer = create_user
    seller = create_user(email: "cart-items-fraud-seller@example.com")
    product = create_product_for(seller)
    token = access_token_for(buyer)

    post "/cart/items", params: {
      cart_item: {
        product_id: product.id,
        quantity: 2,
        price: "0.01",
      },
    }, headers: {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE" => "application/json",
    }, as: :json

    assert_response :success
    line = JSON.parse(response.body).dig("data", "cart", "items", 0)
    assert_equal format("%.2f", product.price), line["unit_price"]
  end

  test "rejects own product" do
    user = create_user(email: "cart-items-fraud-own@example.com")
    product = create_product_for(user)
    token = access_token_for(user)

    post "/cart/items", params: {
      cart_item: {
        product_id: product.id,
        quantity: 1,
      },
    }, headers: {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE" => "application/json",
    }, as: :json

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
  end

  test "rejects inactive and deleted products" do
    buyer = create_user(email: "cart-items-fraud-buyer-inactive@example.com")
    seller = create_user(email: "cart-items-fraud-seller-inactive@example.com")
    inactive = create_product_for(seller, title: "Inactive Product")
    inactive.update!(active: false)
    deleted = create_product_for(seller, title: "Deleted Product")
    deleted.update!(deleted_at: Time.current)
    token = access_token_for(buyer)

    [inactive.id, deleted.id].each do |product_id|
      post "/cart/items", params: {
        cart_item: {
          product_id: product_id,
          quantity: 1,
        },
      }, headers: {
        "Authorization" => "Bearer #{token}",
        "CONTENT_TYPE" => "application/json",
      }, as: :json

      assert_response :unprocessable_entity
      assert_equal "payload invalido", JSON.parse(response.body)["error"]
    end
  end

  test "rejects forged payload keys for targeting" do
    buyer = create_user(email: "cart-items-fraud-target-buyer@example.com")
    seller = create_user(email: "cart-items-fraud-target-seller@example.com")
    product = create_product_for(seller)
    token = access_token_for(buyer)

    post "/cart/items", params: {
      cart_item: {
        product_id: product.id,
        quantity: 1,
        user_id: seller.id,
      },
    }, headers: {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE" => "application/json",
    }, as: :json

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
  end
end
