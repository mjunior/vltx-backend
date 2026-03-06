require "test_helper"

module Products
  class PublicProductDetailTest < ActiveSupport::TestCase
    def create_user(email: "public-detail-service@example.com")
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

    test "returns success for public visible product" do
      user = create_user
      product = create_product_for(
        user,
        title: "Mouse Gamer",
        description: "Sensor preciso para jogos",
        price: "299.99"
      )

      result = PublicProductDetail.call(id: product.id)

      assert result.success?
      assert_equal product.id, result.product.id
    end

    test "returns failure for malformed uuid" do
      result = PublicProductDetail.call(id: "abc")

      refute result.success?
      assert_nil result.product
    end

    test "returns failure for unknown uuid" do
      result = PublicProductDetail.call(id: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")

      refute result.success?
      assert_nil result.product
    end

    test "returns failure for inactive product" do
      user = create_user(email: "public-detail-service-inactive@example.com")
      product = create_product_for(
        user,
        title: "Inativo",
        description: "Descricao valida para item inativo",
        price: "49.90",
        active: false
      )

      result = PublicProductDetail.call(id: product.id)

      refute result.success?
      assert_nil result.product
    end

    test "returns failure for soft-deleted product" do
      user = create_user(email: "public-detail-service-deleted@example.com")
      product = create_product_for(
        user,
        title: "Deletado",
        description: "Descricao valida para item deletado",
        price: "59.90",
        deleted_at: Time.current
      )

      result = PublicProductDetail.call(id: product.id)

      refute result.success?
      assert_nil result.product
    end
  end
end
