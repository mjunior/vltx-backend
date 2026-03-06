require "test_helper"

module Products
  class PrivateListingTest < ActiveSupport::TestCase
    def create_user(email: "private-listing@example.com")
      Users::Create.call(
        email: email,
        password: "password123",
        password_confirmation: "password123"
      ).user
    end

    def create_product_for(user, title:, active: true, deleted_at: nil, created_at: Time.current)
      product = Products::Create.call(user: user, params: {
        title: title,
        description: "Descricao valida para listagem privada",
        price: "100.00",
        stock_quantity: 1
      }).product
      product.update!(active: active, deleted_at: deleted_at, created_at: created_at)
      product
    end

    test "returns only authenticated user non deleted products" do
      owner = create_user
      other = create_user(email: "private-listing-other@example.com")

      visible_owner = create_product_for(owner, title: "Owner Product")
      create_product_for(owner, title: "Owner Deleted", deleted_at: Time.current)
      create_product_for(other, title: "Other Product")

      result = PrivateListing.call(user: owner)

      assert result.success?
      assert_equal 1, result.total
      assert_equal [visible_owner.id], result.products.map(&:id)
    end

    test "includes active and inactive products and sorts newest first deterministically" do
      user = create_user(email: "private-listing-order@example.com")
      oldest = create_product_for(user, title: "Oldest", created_at: 2.hours.ago)
      inactive = create_product_for(user, title: "Inactive", active: false, created_at: 1.hour.ago)
      newest = create_product_for(user, title: "Newest", created_at: Time.current)

      result = PrivateListing.call(user: user)

      assert result.success?
      assert_equal 3, result.total
      assert_equal [newest.id, inactive.id, oldest.id], result.products.map(&:id)
      assert_equal [true, false, true], result.products.map(&:active)
    end

    test "fails when user is nil" do
      result = PrivateListing.call(user: nil)

      refute result.success?
      assert_equal [], result.products
      assert_equal 0, result.total
    end
  end
end
