require "test_helper"

class ProductIndexTest < ActionDispatch::IntegrationTest
  def create_user(email: "seller-index@example.com", password: "password123")
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

  def create_product_for(user, title:, active: true, deleted_at: nil, created_at: Time.current)
    product = Products::Create.call(user: user, params: {
      title: title,
      description: "Descricao valida para listagem privada",
      price: "100.00",
      stock_quantity: 2
    }).product
    product.update!(active: active, deleted_at: deleted_at, created_at: created_at)
    product
  end

  test "returns token invalido without authorization" do
    get "/products"

    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]
  end

  test "lists only logged user products with data and meta total" do
    owner = create_user
    other = create_user(email: "other-index@example.com")
    token = access_token_for(owner)

    oldest = create_product_for(owner, title: "Produto Antigo", created_at: 2.hours.ago)
    inactive = create_product_for(owner, title: "Produto Inativo", active: false, created_at: 1.hour.ago)
    newest = create_product_for(owner, title: "Produto Novo", created_at: Time.current)
    create_product_for(owner, title: "Produto Deletado", deleted_at: Time.current, created_at: 30.minutes.ago)
    create_product_for(other, title: "Produto Outro User", created_at: 3.hours.ago)

    get "/products", headers: {
      "Authorization" => "Bearer #{token}"
    }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 3, body.dig("meta", "total")

    data = body.fetch("data")
    assert_equal [newest.id, inactive.id, oldest.id], data.map { |item| item.fetch("id") }
    assert_equal [true, false, true], data.map { |item| item.fetch("active") }
    assert_equal %w[active description id price stock_quantity title], data.first.keys.sort
  end

  test "returns empty list when user has no products" do
    user = create_user(email: "empty-products-index@example.com")
    token = access_token_for(user)

    get "/products", headers: {
      "Authorization" => "Bearer #{token}"
    }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal [], body.fetch("data")
    assert_equal 0, body.dig("meta", "total")
  end
end
