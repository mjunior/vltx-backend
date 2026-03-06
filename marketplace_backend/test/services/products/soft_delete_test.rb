require "test_helper"

module Products
  class SoftDeleteTest < ActiveSupport::TestCase
    def create_user(email: "service-soft-delete@example.com")
      Users::Create.call(
        email: email,
        password: "password123",
        password_confirmation: "password123"
      ).user
    end

    def create_product_for(user, active: true)
      Products::Create.call(user: user, params: {
        title: "Produto",
        description: "Descricao valida para soft delete de produto",
        price: "70.00",
        stock_quantity: 6
      }).product.tap { |product| product.update!(active: active) }
    end

    test "soft deletes owned product using only deleted_at" do
      user = create_user
      product = create_product_for(user, active: true)

      result = SoftDelete.call(user: user, product_id: product.id)

      assert result.success?
      product.reload
      assert product.deleted_at.present?
      assert_equal true, product.active
    end

    test "returns not_found for product from another seller" do
      owner = create_user(email: "owner-soft-delete-service@example.com")
      intruder = create_user(email: "intruder-soft-delete-service@example.com")
      product = create_product_for(owner)

      result = SoftDelete.call(user: intruder, product_id: product.id)

      assert_not result.success?
      assert_equal :not_found, result.error_code
    end

    test "returns not_found for already deleted product" do
      user = create_user(email: "already-deleted-soft-service@example.com")
      product = create_product_for(user)
      product.update!(deleted_at: Time.current)

      result = SoftDelete.call(user: user, product_id: product.id)

      assert_not result.success?
      assert_equal :not_found, result.error_code
    end
  end
end
