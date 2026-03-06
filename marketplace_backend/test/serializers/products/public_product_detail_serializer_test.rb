require "test_helper"

module Products
  class PublicProductDetailSerializerTest < ActiveSupport::TestCase
    def create_user(email: "detail-serializer@example.com")
      Users::Create.call(
        email: email,
        password: "password123",
        password_confirmation: "password123"
      ).user
    end

    test "serializes only allowed public detail fields" do
      user = create_user
      product = Product.new(
        user: user,
        title: "Notebook Pro",
        description: "Descricao valida para serializer publico",
        price: "3200.50",
        stock_quantity: 12,
        active: true
      )

      payload = PublicProductDetailSerializer.call(product: product)

      assert_equal %i[id title description price stock_quantity], payload.keys
      assert_equal "Notebook Pro", payload[:title]
      assert_equal "Descricao valida para serializer publico", payload[:description]
      assert_equal 3200.5, payload[:price]
      assert_equal 12, payload[:stock_quantity]
    end

    test "clamps negative stock to zero defensively" do
      user = create_user(email: "detail-serializer-negative@example.com")
      product = Product.new(
        user: user,
        title: "Produto Corrompido",
        description: "Descricao valida para clamp defensivo",
        price: "10.00",
        stock_quantity: -5,
        active: true
      )

      payload = PublicProductDetailSerializer.call(product: product)

      assert_equal 0, payload[:stock_quantity]
    end
  end
end
