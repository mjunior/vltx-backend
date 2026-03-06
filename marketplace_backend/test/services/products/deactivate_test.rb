require "test_helper"

module Products
  class DeactivateTest < ActiveSupport::TestCase
    def create_user(email: "service-deactivate@example.com")
      Users::Create.call(
        email: email,
        password: "password123",
        password_confirmation: "password123"
      ).user
    end

    def create_product_for(user, active: true)
      Products::Create.call(user: user, params: {
        title: "Produto",
        description: "Descricao valida para desativacao de produto",
        price: "50.00",
        stock_quantity: 5
      }).product.tap { |product| product.update!(active: active) }
    end

    test "deactivates owned active product" do
      user = create_user
      product = create_product_for(user, active: true)

      result = Deactivate.call(user: user, product_id: product.id)

      assert result.success?
      assert_equal false, product.reload.active
    end

    test "is idempotent when product already inactive" do
      user = create_user(email: "already-inactive-service@example.com")
      product = create_product_for(user, active: false)

      result = Deactivate.call(user: user, product_id: product.id)

      assert result.success?
      assert_equal false, product.reload.active
    end

    test "returns not_found for product from another seller" do
      owner = create_user(email: "owner-deactivate-service@example.com")
      intruder = create_user(email: "intruder-deactivate-service@example.com")
      product = create_product_for(owner)

      result = Deactivate.call(user: intruder, product_id: product.id)

      assert_not result.success?
      assert_equal :not_found, result.error_code
    end
  end
end
