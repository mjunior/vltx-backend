require "test_helper"

class ProductRatingTest < ActiveSupport::TestCase
  def create_user(email: "product-rating-buyer@example.com")
    Users::Create.call(
      email: email,
      password: "password123",
      password_confirmation: "password123"
    ).user
  end

  def create_product_for(user, attrs = {})
    defaults = {
      title: "Produto Rating",
      description: "Descricao valida para product rating",
      price: "20.00",
      stock_quantity: 4
    }

    Products::Create.call(user: user, params: defaults.merge(attrs)).product
  end

  def create_delivered_order_item
    buyer = create_user
    seller = create_user(email: "product-rating-seller@example.com")
    product = create_product_for(seller)
    cart = Cart.create!(user: buyer, status: :finished)
    checkout_group = CheckoutGroup.create!(buyer: buyer, source_cart: cart, currency: "BRL", total_items: 1, subtotal_cents: 2000)
    order = Order.create!(user: buyer, seller: seller, source_cart: cart, checkout_group: checkout_group, status: :paid, currency: "BRL", total_items: 1, subtotal_cents: 2000)
    Orders::TransitionRecorder.record!(order: order, to_status: :paid, action: :checkout, actor: buyer, actor_role: OrderTransition::ACTOR_ROLES[:buyer], metadata: { "source" => "seed" })
    Orders::TransitionRecorder.record!(order: order.reload, to_status: :in_separation, action: :advance, actor: seller, actor_role: OrderTransition::ACTOR_ROLES[:seller], metadata: { "source" => "seed" })
    Orders::TransitionRecorder.record!(order: order.reload, to_status: :confirmed, action: :advance, actor: seller, actor_role: OrderTransition::ACTOR_ROLES[:seller], metadata: { "source" => "seed" })
    Orders::TransitionRecorder.record!(order: order.reload, to_status: :delivered, action: :deliver, actor: buyer, actor_role: OrderTransition::ACTOR_ROLES[:buyer], metadata: { "source" => "seed" })
    item = OrderItem.create!(order: order.reload, product: product, seller: seller, product_title: product.title, quantity: 1, unit_price_cents: 2000, line_subtotal_cents: 2000)
    [buyer, product, order, item]
  end

  test "is valid for delivered purchase context" do
    buyer, product, order, item = create_delivered_order_item
    rating = ProductRating.new(order: order, order_item: item, buyer: buyer, product: product, score: 5, comment: "Muito bom")

    assert rating.valid?
  end

  test "requires delivered purchase context" do
    buyer = create_user(email: "product-rating-undelivered-buyer@example.com")
    seller = create_user(email: "product-rating-undelivered-seller@example.com")
    product = create_product_for(seller)
    cart = Cart.create!(user: buyer, status: :finished)
    checkout_group = CheckoutGroup.create!(buyer: buyer, source_cart: cart, currency: "BRL", total_items: 1, subtotal_cents: 2000)
    order = Order.create!(user: buyer, seller: seller, source_cart: cart, checkout_group: checkout_group, status: :paid, currency: "BRL", total_items: 1, subtotal_cents: 2000)
    Orders::TransitionRecorder.record!(order: order, to_status: :paid, action: :checkout, actor: buyer, actor_role: OrderTransition::ACTOR_ROLES[:buyer], metadata: { "source" => "seed" })
    item = OrderItem.create!(order: order, product: product, seller: seller, product_title: product.title, quantity: 1, unit_price_cents: 2000, line_subtotal_cents: 2000)
    rating = ProductRating.new(order: order, order_item: item, buyer: buyer, product: product, score: 4, comment: "Ainda nao entregue")

    assert_not rating.valid?
    assert_includes rating.errors[:order_item_id], "must belong to delivered purchase"
  end
end
