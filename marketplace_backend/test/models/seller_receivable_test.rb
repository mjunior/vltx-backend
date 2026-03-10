require "test_helper"

class SellerReceivableTest < ActiveSupport::TestCase
  def create_user(email: "seller-receivable-buyer@example.com")
    Users::Create.call(
      email: email,
      password: "password123",
      password_confirmation: "password123"
    ).user
  end

  def create_order_context
    buyer = create_user
    seller = create_user(email: "seller-receivable-seller@example.com")
    cart = Cart.create!(user: buyer, status: :finished)
    checkout_group = CheckoutGroup.create!(
      buyer: buyer,
      source_cart: cart,
      currency: "BRL",
      total_items: 2,
      subtotal_cents: 50_00
    )
    order = Order.create!(
      user: buyer,
      seller: seller,
      source_cart: cart,
      checkout_group: checkout_group,
      status: :paid,
      currency: "BRL",
      total_items: 2,
      subtotal_cents: 50_00
    )

    { buyer: buyer, seller: seller, checkout_group: checkout_group, order: order }
  end

  test "is valid when aligned with order context" do
    context = create_order_context
    receivable = SellerReceivable.new(
      order: context[:order],
      seller: context[:seller],
      buyer: context[:buyer],
      checkout_group: context[:checkout_group],
      status: :pending,
      amount_cents: 50_00
    )

    assert receivable.valid?
  end

  test "requires identities and checkout group to match order" do
    context = create_order_context
    intruder = create_user(email: "seller-receivable-intruder@example.com")
    wrong_group = CheckoutGroup.create!(
      buyer: context[:buyer],
      source_cart: Cart.create!(user: context[:buyer], status: :finished),
      currency: "BRL",
      total_items: 1,
      subtotal_cents: 10_00
    )
    receivable = SellerReceivable.new(
      order: context[:order],
      seller: intruder,
      buyer: context[:buyer],
      checkout_group: wrong_group,
      status: :pending,
      amount_cents: 50_00
    )

    assert_not receivable.valid?
    assert_includes receivable.errors[:seller_id], "must match order seller"
    assert_includes receivable.errors[:checkout_group_id], "must match order checkout group"
  end
end
