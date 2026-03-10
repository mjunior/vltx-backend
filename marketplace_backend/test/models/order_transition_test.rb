require "test_helper"

class OrderTransitionTest < ActiveSupport::TestCase
  def create_user(email: "order-transition-buyer@example.com")
    Users::Create.call(
      email: email,
      password: "password123",
      password_confirmation: "password123"
    ).user
  end

  def create_order(status: :paid)
    buyer = create_user
    seller = create_user(email: "order-transition-seller@example.com")
    cart = Cart.create!(user: buyer, status: :finished)
    checkout_group = CheckoutGroup.create!(
      buyer: buyer,
      source_cart: cart,
      currency: "BRL",
      total_items: 1,
      subtotal_cents: 100_00
    )

    Order.create!(
      user: buyer,
      seller: seller,
      source_cart: cart,
      checkout_group: checkout_group,
      status: status,
      currency: "BRL",
      total_items: 1,
      subtotal_cents: 100_00
    )
  end

  test "is valid with actor scoped data and order statuses" do
    order = create_order

    transition = OrderTransition.new(
      order: order,
      actor: order.user,
      actor_role: :buyer,
      action: "cancel",
      from_status: "paid",
      to_status: "canceled",
      position: 1,
      metadata: { "source" => "test" }
    )

    assert transition.valid?
  end

  test "requires actor presence to match actor role" do
    order = create_order
    transition = OrderTransition.new(
      order: order,
      actor_role: :buyer,
      action: "cancel",
      from_status: "paid",
      to_status: "canceled",
      position: 1,
      metadata: {}
    )

    assert_not transition.valid?
    assert_includes transition.errors[:actor_id], "must match actor role"
  end

  test "allows system transitions without actor" do
    order = create_order
    transition = OrderTransition.new(
      order: order,
      actor_role: :system,
      action: "backfill",
      from_status: nil,
      to_status: "paid",
      position: 1,
      metadata: {}
    )

    assert transition.valid?
  end
end
