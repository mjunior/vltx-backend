require "test_helper"

class OrderItemTest < ActiveSupport::TestCase
  def create_user(email: "order-item-buyer@example.com")
    Users::Create.call(
      email: email,
      password: "password123",
      password_confirmation: "password123"
    ).user
  end

  def create_product_for(user, attrs = {})
    defaults = {
      title: "Produto Snapshot",
      description: "Descricao valida para snapshot de pedido",
      price: "12.50",
      stock_quantity: 9,
    }

    Products::Create.call(user: user, params: defaults.merge(attrs)).product
  end

  def create_order_for(buyer:, seller:)
    cart = Cart.create!(user: buyer, status: :finished)
    Order.create!(
      user: buyer,
      seller: seller,
      source_cart: cart,
      checkout_group: CheckoutGroup.create!(
        buyer: buyer,
        source_cart: cart,
        currency: "BRL",
        total_items: 1,
        subtotal_cents: 1250
      ),
      status: :paid,
      currency: "BRL",
      total_items: 1,
      subtotal_cents: 1250
    )
  end

  test "is valid with snapshot fields and matching seller" do
    buyer = create_user
    seller = create_user(email: "order-item-seller@example.com")
    product = create_product_for(seller)
    order_item = OrderItem.new(
      order: create_order_for(buyer:, seller:),
      product: product,
      seller: seller,
      product_title: product.title,
      quantity: 2,
      unit_price_cents: 1250,
      line_subtotal_cents: 2500
    )

    assert order_item.valid?
  end

  test "requires seller match and line subtotal consistency" do
    buyer = create_user(email: "order-item-invalid-buyer@example.com")
    seller = create_user(email: "order-item-invalid-seller@example.com")
    other_seller = create_user(email: "order-item-other-seller@example.com")
    product = create_product_for(seller)
    order_item = OrderItem.new(
      order: create_order_for(buyer:, seller:),
      product: product,
      seller: other_seller,
      product_title: product.title,
      quantity: 2,
      unit_price_cents: 1250,
      line_subtotal_cents: 1000
    )

    assert_not order_item.valid?
    assert_includes order_item.errors[:seller_id], "must match order seller"
    assert_includes order_item.errors[:line_subtotal_cents], "must match quantity times unit price"
  end
end
