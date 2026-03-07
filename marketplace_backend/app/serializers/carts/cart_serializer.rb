require "bigdecimal"

module Carts
  class CartSerializer
    class << self
      def call(cart:)
        cart_items = cart.cart_items.includes(:product).order(created_at: :asc, id: :asc)
        subtotal = BigDecimal("0")
        cart_items.each do |item|
          subtotal += (item.product.price * item.quantity)
        end

        {
          id: cart.id,
          created_at: cart.created_at,
          updated_at: cart.updated_at,
          total_items: cart_items.sum(&:quantity),
          subtotal: format("%.2f", subtotal),
          items: cart_items.map do |item|
            unit_price = item.product.price
            {
              id: item.id,
              product_id: item.product_id,
              product: Products::PublicProductSerializer.call(product: item.product),
              quantity: item.quantity,
              unit_price: format("%.2f", unit_price),
              line_subtotal: format("%.2f", unit_price * item.quantity),
            }
          end,
        }
      end
    end
  end
end
