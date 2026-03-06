require "test_helper"
require "securerandom"

module Products
  class CreateTest < ActiveSupport::TestCase
    def create_user(email: "service-product@example.com")
      Users::Create.call(
        email: email,
        password: "password123",
        password_confirmation: "password123"
      ).user
    end

    test "creates product for authenticated user" do
      user = create_user

      result = Create.call(user: user, params: {
        title: "Cadeira Ergonomica",
        description: "Cadeira com ajuste lombar e apoio de bracos",
        price: "1299.90",
        stock_quantity: 8
      })

      assert result.success?
      assert_equal user.id, result.product.user_id
      assert_equal "1299.9", result.product.price.to_s("F")
      assert_equal true, result.product.active
    end

    test "fails when payload includes owner fields" do
      user = create_user(email: "owner-forge-service@example.com")

      result = Create.call(user: user, params: {
        title: "Produto",
        description: "Descricao valida para criacao de produto",
        price: "20.00",
        stock_quantity: 3,
        owner_id: SecureRandom.uuid
      })

      assert_not result.success?
    end

    test "fails when user is nil" do
      result = Create.call(user: nil, params: {
        title: "Produto",
        description: "Descricao valida para criacao de produto",
        price: "20.00",
        stock_quantity: 3
      })

      assert_not result.success?
    end

    test "fails when price precision is invalid" do
      user = create_user(email: "precision-service-product@example.com")

      result = Create.call(user: user, params: {
        title: "Produto",
        description: "Descricao valida para criacao de produto",
        price: "20.999",
        stock_quantity: 3
      })

      assert_not result.success?
    end

    test "fails when stock is negative or non-integer" do
      user = create_user(email: "stock-service-product@example.com")

      negative = Create.call(user: user, params: {
        title: "Produto",
        description: "Descricao valida para criacao de produto",
        price: "20.00",
        stock_quantity: -1
      })
      string_invalid = Create.call(user: user, params: {
        title: "Produto",
        description: "Descricao valida para criacao de produto",
        price: "20.00",
        stock_quantity: "3.5"
      })

      assert_not negative.success?
      assert_not string_invalid.success?
    end

    test "fails when limits are invalid" do
      user = create_user(email: "limits-service-product@example.com")

      result = Create.call(user: user, params: {
        title: "Produto",
        description: "Descricao valida para criacao de produto",
        price: "10000000.00",
        stock_quantity: 1_000_000
      })

      assert_not result.success?
    end

    test "sanitizes html from description" do
      user = create_user(email: "sanitize-service-product@example.com")

      result = Create.call(user: user, params: {
        title: "Mouse",
        description: "<img src=x onerror=alert(1)>Mouse com sensor optico 8k",
        price: "199.90",
        stock_quantity: 2
      })

      assert result.success?
      assert_equal "Mouse com sensor optico 8k", result.product.description
    end
  end
end
