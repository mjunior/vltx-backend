require "test_helper"

class AdminProductsIndexTest < ActionDispatch::IntegrationTest
  def create_user(email: "admin-products-user@example.com", password: "password123")
    Users::Create.call(email: email, password: password, password_confirmation: password).user
  end

  def create_admin(email: "admin-products-admin@example.com", password: "password123")
    Admin.create!(email: email, password: password, password_confirmation: password)
  end

  def admin_access_token(admin)
    post "/admin/auth/login", params: { email: admin.email, password: "password123" }, as: :json
    JSON.parse(response.body).dig("data", "access_token")
  end

  def create_product_for(user, title:, deleted_at: nil)
    product = Products::Create.call(user: user, params: {
      title: title,
      description: "Descricao valida para listagem administrativa #{title}",
      price: "20.00",
      stock_quantity: 3
    }).product
    product.update!(deleted_at: deleted_at) if deleted_at.present?
    product
  end

  test "admin lists active and soft deleted products" do
    seller = create_user
    active_product = create_product_for(seller, title: "Produto Ativo Admin")
    deleted_product = create_product_for(seller, title: "Produto Deletado Admin", deleted_at: Time.current)
    admin = create_admin
    admin_token = admin_access_token(admin)

    get "/admin/products", headers: { "Authorization" => "Bearer #{admin_token}" }, as: :json

    assert_response :success
    products = JSON.parse(response.body).dig("data", "products")
    rows = products.index_by { |row| row.fetch("id") }

    assert_equal 2000, rows.fetch(active_product.id).fetch("price_cents")
    assert_nil rows.fetch(active_product.id)["deleted_at"]
    assert rows.fetch(deleted_product.id)["deleted_at"].present?
  end

  test "admin sees product detail" do
    seller = create_user(email: "admin-products-show-user@example.com")
    product = create_product_for(seller, title: "Produto Show Admin")
    admin = create_admin(email: "admin-products-show-admin@example.com")
    admin_token = admin_access_token(admin)

    get "/admin/products/#{product.id}", headers: { "Authorization" => "Bearer #{admin_token}" }, as: :json

    assert_response :success
    body = JSON.parse(response.body).fetch("data")
    assert_equal product.id, body.fetch("id")
    assert_equal seller.id, body.fetch("seller_id")
    assert_equal 2000, body.fetch("price_cents")
  end
end
