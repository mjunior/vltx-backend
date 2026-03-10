module Orders
  class OrderItemSerializer
    class << self
      def call(order_item:)
        {
          id: order_item.id,
          product_id: order_item.product_id,
          seller_id: order_item.seller_id,
          product_title: order_item.product_title,
          quantity: order_item.quantity,
          unit_price_cents: order_item.unit_price_cents,
          unit_price: format("%.2f", order_item.unit_price_cents / 100.0),
          line_subtotal_cents: order_item.line_subtotal_cents,
          line_subtotal: format("%.2f", order_item.line_subtotal_cents / 100.0)
        }
      end
    end
  end
end
