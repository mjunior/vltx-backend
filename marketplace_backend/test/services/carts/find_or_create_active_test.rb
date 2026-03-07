require "test_helper"

module Carts
  class FindOrCreateActiveTest < ActiveSupport::TestCase
    def create_user(email: "cart-service@example.com")
      Users::Create.call(
        email: email,
        password: "password123",
        password_confirmation: "password123"
      ).user
    end

    test "creates active cart when user has none" do
      user = create_user

      result = FindOrCreateActive.call(user: user)

      assert result.success?
      assert_equal user.id, result.cart.user_id
      assert_equal "active", result.cart.status
      assert_equal 1, user.carts.active.count
    end

    test "returns existing active cart when already present" do
      user = create_user(email: "cart-service-existing@example.com")
      existing = Cart.create!(user: user, status: :active)

      result = FindOrCreateActive.call(user: user)

      assert result.success?
      assert_equal existing.id, result.cart.id
      assert_equal 1, user.carts.active.count
    end

    test "returns failure without user" do
      result = FindOrCreateActive.call(user: nil)

      assert_not result.success?
      assert_nil result.cart
    end

    test "recovers from unique conflict by returning existing active cart" do
      user = create_user(email: "cart-service-race@example.com")
      existing = Cart.create!(user: user, status: :active)

      cart_singleton = Cart.singleton_class
      cart_singleton.alias_method :__original_transaction_for_test, :transaction
      cart_singleton.define_method(:transaction) do |*|
        raise ActiveRecord::RecordNotUnique
      end

      begin
        result = FindOrCreateActive.call(user: user)

        assert result.success?
        assert_equal existing.id, result.cart.id
      ensure
        cart_singleton.alias_method :transaction, :__original_transaction_for_test
        cart_singleton.remove_method :__original_transaction_for_test
      end
    end
  end
end
