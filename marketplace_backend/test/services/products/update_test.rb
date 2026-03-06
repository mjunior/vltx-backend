require "test_helper"
require "securerandom"

module Products
  class UpdateTest < ActiveSupport::TestCase
    def create_user(email: "service-update@example.com")
      Users::Create.call(
        email: email,
        password: "password123",
        password_confirmation: "password123"
      ).user
    end

    def create_product_for(user)
      Products::Create.call(user: user, params: {
        title: "Produto",
        description: "Descricao valida para update de produto",
        price: "99.90",
        stock_quantity: 7
      }).product
    end

    test "updates owned product with allowed fields" do
      user = create_user
      product = create_product_for(user)

      result = Update.call(user: user, product_id: product.id, params: {
        title: "Produto Novo",
        price: "199.90",
        active: true
      })

      assert result.success?
      product.reload
      assert_equal "Produto Novo", product.title
      assert_equal "199.9", product.price.to_s("F")
      assert_equal true, product.active
    end

    test "returns not_found for product from another seller" do
      owner = create_user(email: "owner-service-update@example.com")
      intruder = create_user(email: "intruder-service-update@example.com")
      product = create_product_for(owner)

      result = Update.call(user: intruder, product_id: product.id, params: { title: "Tentativa" })

      assert_not result.success?
      assert_equal :not_found, result.error_code
    end

    test "returns invalid payload for active false" do
      user = create_user(email: "active-false-service-update@example.com")
      product = create_product_for(user)

      result = Update.call(user: user, product_id: product.id, params: { active: false })

      assert_not result.success?
      assert_equal :invalid_payload, result.error_code
    end

    test "returns invalid payload for unknown fields" do
      user = create_user(email: "unknown-service-update@example.com")
      product = create_product_for(user)

      result = Update.call(user: user, product_id: product.id, params: {
        title: "Ok",
        owner_id: SecureRandom.uuid
      })

      assert_not result.success?
      assert_equal :invalid_payload, result.error_code
    end
  end
end
