require "test_helper"

class CheckoutGroupTest < ActiveSupport::TestCase
  def create_user(email: "checkout-group-buyer@example.com")
    Users::Create.call(
      email: email,
      password: "password123",
      password_confirmation: "password123"
    ).user
  end

  def create_cart_for(user)
    Cart.create!(user: user, status: :finished)
  end

  test "is valid with buyer source cart and positive totals" do
    buyer = create_user
    group = CheckoutGroup.new(
      buyer: buyer,
      source_cart: create_cart_for(buyer),
      currency: "BRL",
      total_items: 3,
      subtotal_cents: 210_00
    )

    assert group.valid?
  end

  test "requires buyer to match source cart owner" do
    buyer = create_user(email: "checkout-group-buyer-mismatch@example.com")
    other = create_user(email: "checkout-group-owner@example.com")
    group = CheckoutGroup.new(
      buyer: buyer,
      source_cart: create_cart_for(other),
      currency: "BRL",
      total_items: 1,
      subtotal_cents: 10_00
    )

    assert_not group.valid?
    assert_includes group.errors[:buyer_id], "must match source cart owner"
  end
end
