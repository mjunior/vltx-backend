require "test_helper"

class PublicProductsIndexTest < ActionDispatch::IntegrationTest
  def create_user(email: "public-index@example.com")
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

  test "returns public catalog without auth and includes meta total" do
    user = create_user
    visible = create_product_for(user, title: "Notebook", description: "Notebook para estudo", price: "3000.00")
    create_product_for(user, title: "Inativo", description: "Nao publica", price: "100.00", active: false)
    create_product_for(user, title: "Deletado", description: "Nao publica", price: "200.00", deleted_at: Time.current)

    get "/public/products"

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.dig("meta", "total")
    assert_equal [visible.id], body.fetch("data").map { |item| item.fetch("id") }
  end

  test "filters by q and price range" do
    user = create_user(email: "public-index-filters@example.com")
    hit = create_product_for(user, title: "Cadeira Gamer", description: "Confortavel", price: "850.00")
    create_product_for(user, title: "Cadeira Simples", description: "Confortavel", price: "150.00")
    create_product_for(user, title: "Mesa", description: "Para cadeira", price: "400.00")

    get "/public/products", params: { q: "cadeira", min_price: "700", max_price: "900" }

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal [hit.id], body.fetch("data").map { |item| item.fetch("id") }
    assert_equal 1, body.dig("meta", "total")
  end

  test "returns payload invalido for invalid price filter" do
    get "/public/products", params: { min_price: "abc" }

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
  end

  test "returns 200 with empty data when no product matches" do
    get "/public/products", params: { q: "nao-existe" }

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal [], body.fetch("data")
    assert_equal 0, body.dig("meta", "total")
  end

  test "supports sort options and newest as default" do
    user = create_user(email: "public-index-sort@example.com")
    oldest = create_product_for(user, title: "Produto Antigo", description: "Descricao antiga valida", price: "300.00")
    sleep 1
    newest = create_product_for(user, title: "Produto Novo", description: "Descricao nova valida", price: "200.00")
    sleep 1
    expensive = create_product_for(user, title: "Produto Caro", description: "Descricao cara valida", price: "900.00")

    get "/public/products"
    default_ids = JSON.parse(response.body).fetch("data").map { |item| item.fetch("id") }

    get "/public/products", params: { sort: "price_asc" }
    asc_ids = JSON.parse(response.body).fetch("data").map { |item| item.fetch("id") }

    get "/public/products", params: { sort: "price_desc" }
    desc_ids = JSON.parse(response.body).fetch("data").map { |item| item.fetch("id") }

    assert_equal [expensive.id, newest.id, oldest.id], default_ids
    assert_equal [newest.id, oldest.id, expensive.id], asc_ids
    assert_equal [expensive.id, oldest.id, newest.id], desc_ids
  end

  test "returns payload invalido for invalid sort" do
    get "/public/products", params: { sort: "invalid_sort" }

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
  end
end
