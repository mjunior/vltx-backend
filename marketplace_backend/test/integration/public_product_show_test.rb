require "test_helper"

class PublicProductShowTest < ActionDispatch::IntegrationTest
  def create_user(email: "public-show@example.com")
    Users::Create.call(
      email: email,
      password: "password123",
      password_confirmation: "password123"
    ).user
  end

  def create_product_for(user, title:, description:, price:, active: true, deleted_at: nil)
    product = Products::Create.call(user: user, params: {
      title: title,
      description: description,
      price: price,
      stock_quantity: 2
    }).product
    product.update!(active: active, deleted_at: deleted_at)
    product
  end

  test "returns public product detail without auth" do
    user = create_user
    product = create_product_for(
      user,
      title: "Teclado Mecanico",
      description: "Switch blue para digitacao",
      price: "399.90"
    )

    get "/public/products/#{product.id}"

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal product.id, body.dig("data", "id")
    assert_equal product.title, body.dig("data", "title")
    assert_equal product.description, body.dig("data", "description")
    assert_equal product.price.to_s("F"), body.dig("data", "price")
    assert_equal product.stock_quantity, body.dig("data", "stock_quantity")
  end

  test "returns not found for invalid uuid" do
    get "/public/products/not-a-uuid"

    assert_response :not_found
    assert_equal "", response.body
  end

  test "returns not found for unknown uuid" do
    get "/public/products/aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"

    assert_response :not_found
    assert_equal "", response.body
  end

  test "returns not found for inactive product" do
    user = create_user(email: "inactive-show@example.com")
    product = create_product_for(
      user,
      title: "Produto Inativo",
      description: "Nao deve aparecer no detalhe",
      price: "50.00",
      active: false
    )

    get "/public/products/#{product.id}"

    assert_response :not_found
    assert_equal "", response.body
  end

  test "returns not found for soft-deleted product" do
    user = create_user(email: "deleted-show@example.com")
    product = create_product_for(
      user,
      title: "Produto Deletado",
      description: "Nao deve aparecer no detalhe",
      price: "90.00",
      deleted_at: Time.current
    )

    get "/public/products/#{product.id}"

    assert_response :not_found
    assert_equal "", response.body
  end
end
