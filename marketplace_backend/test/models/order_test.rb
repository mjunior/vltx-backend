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

  def create_checkout_group_for(user, cart:)
    CheckoutGroup.create!(
      buyer: user,
      source_cart: cart,
      currency: "BRL",
      total_items: 2,
      subtotal_cents: 1500
    )
  end

  test "is valid with buyer seller source cart and positive totals" do
    buyer = create_user
    seller = create_user(email: "order-model-seller@example.com")
    cart = create_cart_for(buyer)
    order = Order.new(
      user: buyer,
      seller: seller,
      source_cart: cart,
      checkout_group: create_checkout_group_for(buyer, cart: cart),
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
    cart = create_cart_for(buyer)
    order = Order.new(
      user: buyer,
      seller: seller,
      source_cart: cart,
      checkout_group: create_checkout_group_for(buyer, cart: cart),
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
    cart = create_cart_for(buyer)
    order = Order.new(
      user: buyer,
      seller: buyer,
      source_cart: cart,
      checkout_group: create_checkout_group_for(buyer, cart: cart),
      status: :paid,
      currency: "BRL",
      total_items: 1,
      subtotal_cents: 100
    )

    assert_not order.valid?
    assert_includes order.errors[:seller_id], "must differ from buyer"
  end

  test "requires checkout group to match buyer and source cart" do
    buyer = create_user(email: "order-model-group-buyer@example.com")
    seller = create_user(email: "order-model-group-seller@example.com")
    other_buyer = create_user(email: "order-model-group-other@example.com")
    cart = create_cart_for(buyer)
    other_cart = create_cart_for(other_buyer)
    mismatched_group = create_checkout_group_for(other_buyer, cart: other_cart)
    order = Order.new(
      user: buyer,
      seller: seller,
      source_cart: cart,
      checkout_group: mismatched_group,
      status: :paid,
      currency: "BRL",
      total_items: 1,
      subtotal_cents: 100
    )

    assert_not order.valid?
    assert_includes order.errors[:checkout_group_id], "must belong to buyer"
    assert_includes order.errors[:checkout_group_id], "must reference the same source cart"
  end
end
