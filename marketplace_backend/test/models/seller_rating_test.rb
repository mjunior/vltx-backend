require "test_helper"

class SellerRatingTest < ActiveSupport::TestCase
  def create_user(email: "seller-rating-buyer@example.com")
    Users::Create.call(
      email: email,
      password: "password123",
      password_confirmation: "password123"
    ).user
  end

  def create_product_for(user, attrs = {})
    defaults = {
      title: "Produto Seller Rating",
      description: "Descricao valida para seller rating",
      price: "21.00",
      stock_quantity: 4
    }

    Products::Create.call(user: user, params: defaults.merge(attrs)).product
  end

  def create_contested_order_item
    buyer = create_user
    seller = create_user(email: "seller-rating-seller@example.com")
    product = create_product_for(seller)
    cart = Cart.create!(user: buyer, status: :finished)
    checkout_group = CheckoutGroup.create!(buyer: buyer, source_cart: cart, currency: "BRL", total_items: 1, subtotal_cents: 2100)
    order = Order.create!(user: buyer, seller: seller, source_cart: cart, checkout_group: checkout_group, status: :paid, currency: "BRL", total_items: 1, subtotal_cents: 2100)
    Orders::TransitionRecorder.record!(order: order, to_status: :paid, action: :checkout, actor: buyer, actor_role: OrderTransition::ACTOR_ROLES[:buyer], metadata: { "source" => "seed" })
    Orders::TransitionRecorder.record!(order: order.reload, to_status: :in_separation, action: :advance, actor: seller, actor_role: OrderTransition::ACTOR_ROLES[:seller], metadata: { "source" => "seed" })
    Orders::TransitionRecorder.record!(order: order.reload, to_status: :confirmed, action: :advance, actor: seller, actor_role: OrderTransition::ACTOR_ROLES[:seller], metadata: { "source" => "seed" })
    Orders::TransitionRecorder.record!(order: order.reload, to_status: :delivered, action: :deliver, actor: buyer, actor_role: OrderTransition::ACTOR_ROLES[:buyer], metadata: { "source" => "seed" })
    Orders::TransitionRecorder.record!(order: order.reload, to_status: :contested, action: :contest, actor: buyer, actor_role: OrderTransition::ACTOR_ROLES[:buyer], metadata: { "source" => "seed" })
    item = OrderItem.create!(order: order.reload, product: product, seller: seller, product_title: product.title, quantity: 1, unit_price_cents: 2100, line_subtotal_cents: 2100)
    [buyer, seller, order, item]
  end

  test "is valid after delivery even if order later became contested" do
    buyer, seller, order, item = create_contested_order_item
    rating = SellerRating.new(order: order, order_item: item, buyer: buyer, seller: seller, score: 5, comment: "Atendimento bom")

    assert rating.valid?
  end
end
