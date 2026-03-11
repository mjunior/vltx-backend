require "test_helper"

class CartItemsCreateTest < ActionDispatch::IntegrationTest
  THROTTLE_IP = "198.51.100.21".freeze

  def create_user(email: "cart-items-create@example.com", password: "password123")
    Users::Create.call(
      email: email,
      password: password,
      password_confirmation: password
    ).user
  end

  def create_product_for(user, attrs = {})
    defaults = {
      title: "Produto Cart Create",
      description: "Descricao valida para create de item no carrinho",
      price: "250.00",
      stock_quantity: 4,
    }

    Products::Create.call(user: user, params: defaults.merge(attrs)).product
  end

  def access_token_for(user, password: "password123")
    post "/auth/login", params: { email: user.email, password: password }, as: :json
    JSON.parse(response.body).dig("data", "access_token")
  end

  test "adds item with product_id and quantity only" do
    buyer = create_user
    seller = create_user(email: "cart-items-create-seller@example.com")
    product = create_product_for(seller)
    token = access_token_for(buyer)

    post "/cart/items", params: {
      cart_item: {
        product_id: product.id,
        quantity: 2,
      },
    }, headers: {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE" => "application/json",
    }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    cart = body.dig("data", "cart")

    assert_equal 2, cart["total_items"]
    assert_equal "500.00", cart["subtotal"]
    assert_equal 1, cart["items"].length
    assert_equal 2, cart["items"][0]["quantity"]
    assert_equal product.title, cart["items"][0].dig("product", "title")
    assert_equal product.description, cart["items"][0].dig("product", "description")
  end

  test "clamps quantity when above stock" do
    buyer = create_user(email: "cart-items-create-clamp-buyer@example.com")
    seller = create_user(email: "cart-items-create-clamp-seller@example.com")
    product = create_product_for(seller, stock_quantity: 1)
    token = access_token_for(buyer)

    post "/cart/items", params: {
      cart_item: {
        product_id: product.id,
        quantity: 20,
      },
    }, headers: {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE" => "application/json",
    }, as: :json

    assert_response :success
    assert_equal 1, JSON.parse(response.body).dig("data", "cart", "items", 0, "quantity")
  end

  test "returns payload invalido when quantity is zero" do
    buyer = create_user(email: "cart-items-create-invalid-qty@example.com")
    seller = create_user(email: "cart-items-create-invalid-qty-seller@example.com")
    product = create_product_for(seller)
    token = access_token_for(buyer)

    post "/cart/items", params: {
      cart_item: {
        product_id: product.id,
        quantity: 0,
      },
    }, headers: {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE" => "application/json",
    }, as: :json

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
  end

  test "returns payload invalido for malformed product id" do
    buyer = create_user(email: "cart-items-create-malformed@example.com")
    token = access_token_for(buyer)

    post "/cart/items", params: {
      cart_item: {
        product_id: "not-a-uuid",
        quantity: 1,
      },
    }, headers: {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE" => "application/json",
    }, as: :json

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
  end

  test "create throttles bursts by authenticated actor" do
    buyer = create_user(email: "cart-items-create-throttle@example.com")
    seller = create_user(email: "cart-items-create-throttle-seller@example.com")
    product = create_product_for(seller)
    token = access_token_for(buyer)

    20.times do
      post "/cart/items", params: {
        cart_item: {
          product_id: product.id,
          quantity: 1,
        },
      }, headers: {
        "Authorization" => "Bearer #{token}",
        "CONTENT_TYPE" => "application/json",
        "REMOTE_ADDR" => THROTTLE_IP,
      }, as: :json
    end

    post "/cart/items", params: {
      cart_item: {
        product_id: product.id,
        quantity: 1,
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
