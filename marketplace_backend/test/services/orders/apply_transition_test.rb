require "test_helper"

module Orders
  class ApplyTransitionTest < ActiveSupport::TestCase
    def create_user(email: "orders-apply-transition-buyer@example.com")
      Users::Create.call(
        email: email,
        password: "password123",
        password_confirmation: "password123"
      ).user
    end

    def create_order(status: :paid)
      buyer = create_user
      seller = create_user(email: "orders-apply-transition-seller@example.com")
      cart = Cart.create!(user: buyer, status: :finished)
      checkout_group = CheckoutGroup.create!(
        buyer: buyer,
        source_cart: cart,
        currency: "BRL",
        total_items: 1,
        subtotal_cents: 100_00
      )
      order = Order.create!(
        user: buyer,
        seller: seller,
        source_cart: cart,
        checkout_group: checkout_group,
        status: status,
        currency: "BRL",
        total_items: 1,
        subtotal_cents: 100_00
      )
      Orders::TransitionRecorder.record!(
        order: order,
        to_status: status,
        action: :checkout,
        actor: buyer,
        actor_role: OrderTransition::ACTOR_ROLES[:buyer],
        metadata: { "source" => "seed" }
      )

      order.reload
    end

    test "seller advances one step at a time" do
      order = create_order(status: :paid)

      first = ApplyTransition.call(order: order, actor: order.seller, action: :advance)
      second = ApplyTransition.call(order: order.reload, actor: order.seller, action: :advance)

      assert first.success?
      assert second.success?
      assert_equal "confirmed", second.order.reload.status
      assert_equal ["paid", "in_separation", "confirmed"], second.order.order_transitions.timeline.map(&:to_status)
    end

    test "rejects seller skip after confirmed" do
      order = create_order(status: :confirmed)

      result = ApplyTransition.call(order: order, actor: order.seller, action: :advance)

      assert_not result.success?
      assert_equal :invalid_transition, result.error_code
    end

    test "rejects intruder actor" do
      order = create_order(status: :paid)
      intruder = create_user(email: "orders-apply-transition-intruder@example.com")

      result = ApplyTransition.call(order: order, actor: intruder, action: :advance)

      assert_not result.success?
      assert_equal :not_found, result.error_code
    end
  end
end
