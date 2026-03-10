require "test_helper"

class AdminProductsSoftDeleteTest < ActionDispatch::IntegrationTest
  def create_user(email: "admin-product-user@example.com", password: "password123")
    Users::Create.call(email: email, password: password, password_confirmation: password).user
  end

  def create_admin(email: "admin-product-admin@example.com", password: "password123")
    Admin.create!(email: email, password: password, password_confirmation: password)
  end

  def create_product_for(user, title: "Produto Moderado")
    Products::Create.call(user: user, params: {
      title: title,
      description: "Descricao valida para moderacao administrativa",
      price: "20.00",
      stock_quantity: 3
    }).product
  end

  def admin_access_token(admin)
    post "/admin/auth/login", params: { email: admin.email, password: "password123" }, as: :json
    JSON.parse(response.body).dig("data", "access_token")
  end

  def user_access_token(user)
    post "/auth/login", params: { email: user.email, password: "password123" }, as: :json
    JSON.parse(response.body).dig("data", "access_token")
  end

  test "admin soft deletes any product and it disappears from public catalog" do
    seller = create_user
    product = create_product_for(seller)
    admin = create_admin
    admin_token = admin_access_token(admin)

    patch "/admin/products/#{product.id}/soft_delete", headers: {
      "Authorization" => "Bearer #{admin_token}",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    assert_response :success
    assert JSON.parse(response.body).dig("data", "deleted_at").present?

    product.reload
    assert product.deleted_at.present?

    get "/public/products", as: :json
    refute_includes JSON.parse(response.body).fetch("data").map { |row| row.fetch("id") }, product.id

    get "/public/products/#{product.id}", as: :json
    assert_response :not_found
  end

  test "seller still sees moderated product in private listing" do
    seller = create_user(email: "seller-private-see@example.com")
    product = create_product_for(seller, title: "Produto Privado Moderado")
    admin = create_admin(email: "admin-private-see@example.com")
    admin_token = admin_access_token(admin)
    seller_token = user_access_token(seller)

    patch "/admin/products/#{product.id}/soft_delete", headers: {
      "Authorization" => "Bearer #{admin_token}",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    get "/products", headers: { "Authorization" => "Bearer #{seller_token}" }, as: :json

    assert_response :success
    payload = JSON.parse(response.body).fetch("data")
    row = payload.find { |item| item.fetch("id") == product.id }
    assert row.present?
    assert row["deleted_at"].present?
  end

  test "returns invalid payload when product is already soft deleted" do
    seller = create_user(email: "already-deleted-seller@example.com")
    product = create_product_for(seller)
    product.update!(deleted_at: Time.current)
    admin = create_admin(email: "already-deleted-admin@example.com")
    admin_token = admin_access_token(admin)

    patch "/admin/products/#{product.id}/soft_delete", headers: {
      "Authorization" => "Bearer #{admin_token}",
      "CONTENT_TYPE" => "application/json"
    }, as: :json

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
  end
end
