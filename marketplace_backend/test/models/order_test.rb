require "test_helper"

class OrderTest < ActiveSupport::TestCase
  def create_user(email: "order-model-buyer@example.com")
    Users::Create.call(
      email: email,
      password: "password123",
      password_confirmation: "password123"
    ).user
  end

  def create_cart_for(user)
    Cart.create!(user: user, status: :finished)
  end

  test "is valid with buyer seller source cart and positive totals" do
    buyer = create_user
    seller = create_user(email: "order-model-seller@example.com")
    order = Order.new(
      user: buyer,
      seller: seller,
      source_cart: create_cart_for(buyer),
      status: :paid,
      currency: "BRL",
      total_items: 2,
      subtotal_cents: 1500
    )

    assert order.valid?
  end

  test "requires positive totals and known status" do
    buyer = create_user(email: "order-model-invalid-buyer@example.com")
    seller = create_user(email: "order-model-invalid-seller@example.com")
    order = Order.new(
      user: buyer,
      seller: seller,
      source_cart: create_cart_for(buyer),
      status: "unknown",
      currency: "BRL",
      total_items: 0,
      subtotal_cents: 0
    )

    assert_not order.valid?
    assert_includes order.errors[:status], "is not included in the list"
    assert_includes order.errors[:total_items], "must be greater than 0"
    assert_includes order.errors[:subtotal_cents], "must be greater than 0"
  end

  test "requires seller different from buyer" do
    buyer = create_user(email: "order-model-same-user@example.com")
    order = Order.new(
      user: buyer,
      seller: buyer,
      source_cart: create_cart_for(buyer),
      status: :paid,
      currency: "BRL",
      total_items: 1,
      subtotal_cents: 100
    )

    assert_not order.valid?
    assert_includes order.errors[:seller_id], "must differ from buyer"
  end
end
