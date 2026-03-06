require "test_helper"
require "securerandom"

class ProductLifecycleTest < ActionDispatch::IntegrationTest
  def create_user(email: "seller-lifecycle@example.com", password: "password123")
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

  def create_product_for(user, title: "Produto Base")
    Products::Create.call(user: user, params: {
      title: title,
      description: "Descricao valida para operacoes de lifecycle",
      price: "100.00",
      stock_quantity: 5
    }).product
  end

  test "updates own product fields and allows active true only" do
    user = create_user
    product = create_product_for(user)
    token = access_token_for(user)

    patch "/products/#{product.id}", params: {
      product: {
        title: "Produto Atualizado",
        active: true
      }
    }, headers: {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    assert_response :success

    product.reload
    assert_equal "Produto Atualizado", product.title
    assert_equal true, product.active
  end

  test "returns payload invalido when update tries active false" do
    user = create_user(email: "active-false-update@example.com")
    product = create_product_for(user)
    token = access_token_for(user)

    patch "/products/#{product.id}", params: {
      product: { active: false }
    }, headers: {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
  end

  test "returns 404 for other seller product update" do
    owner = create_user(email: "owner-update-404@example.com")
    intruder = create_user(email: "intruder-update-404@example.com")
    product = create_product_for(owner)
    token = access_token_for(intruder)

    patch "/products/#{product.id}", params: {
      product: { title: "Tentativa" }
    }, headers: {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    assert_response :not_found
    assert_equal "nao encontrado", JSON.parse(response.body)["error"]
  end

  test "returns 404 for non-existent product update" do
    user = create_user(email: "missing-update-404@example.com")
    token = access_token_for(user)

    patch "/products/#{SecureRandom.uuid}", params: {
      product: { title: "Tentativa" }
    }, headers: {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    assert_response :not_found
    assert_equal "nao encontrado", JSON.parse(response.body)["error"]
  end

  test "deactivates own product and returns success" do
    user = create_user(email: "deactivate-own@example.com")
    product = create_product_for(user)
    token = access_token_for(user)

    patch "/products/#{product.id}/deactivate", headers: {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    assert_response :success
    assert_equal false, product.reload.active
  end

  test "deactivate is idempotent when product already inactive" do
    user = create_user(email: "deactivate-idempotent@example.com")
    product = create_product_for(user)
    product.update!(active: false)
    token = access_token_for(user)

    patch "/products/#{product.id}/deactivate", headers: {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    assert_response :success
    assert_equal false, product.reload.active
  end

  test "returns 404 when deactivating product from another seller" do
    owner = create_user(email: "owner-deactivate-404@example.com")
    intruder = create_user(email: "intruder-deactivate-404@example.com")
    product = create_product_for(owner)
    token = access_token_for(intruder)

    patch "/products/#{product.id}/deactivate", headers: {
      "Authorization" => "Bearer #{token}",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    assert_response :not_found
    assert_equal "nao encontrado", JSON.parse(response.body)["error"]
  end
end
