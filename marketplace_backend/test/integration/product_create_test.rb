require "test_helper"

class ProductCreateTest < ActionDispatch::IntegrationTest
  def create_user(email: "seller-create@example.com", password: "password123")
    Users::Create.call(
      email: email,
      password: password,
      password_confirmation: password
    ).user
  end

  def access_token_for(user, password: "password123")
    post "/auth/login", params: {
      email: user.email,
      password: password
    }, as: :json

    JSON.parse(response.body).dig("data", "access_token")
  end

  test "creates product with authenticated seller and omits owner fields" do
    user = create_user
    access_token = access_token_for(user)

    post "/products", params: {
      product: {
        title: "Monitor 27",
        description: "Monitor ips 27 polegadas com 165hz para games",
        price: "2599.99",
        stock_quantity: 15
      }
    }, headers: {
      "Authorization" => "Bearer #{access_token}",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    assert_response :created

    body = JSON.parse(response.body)
    data = body.fetch("data")
    assert data["id"].present?
    assert_equal "Monitor 27", data["title"]
    assert_equal "2599.99", data["price"]
    assert_equal 15, data["stock_quantity"]
    assert_equal true, data["active"]
    assert_nil data["owner_id"]
    assert_nil data["user_id"]

    product = Product.find(data["id"])
    assert_equal user.id, product.user_id
  end

  test "returns token invalido without authorization" do
    post "/products", params: {
      product: {
        title: "Produto",
        description: "Descricao valida para criacao de produto",
        price: "10.00",
        stock_quantity: 1
      }
    }, as: :json

    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]
  end

  test "returns payload invalido when product root is missing" do
    user = create_user(email: "missing-root-product@example.com")
    access_token = access_token_for(user)

    post "/products", params: {
      title: "Produto",
      description: "Descricao valida para criacao de produto",
      price: "10.00",
      stock_quantity: 1
    }, headers: {
      "Authorization" => "Bearer #{access_token}",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
  end
end
