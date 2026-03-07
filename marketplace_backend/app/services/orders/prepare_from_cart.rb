require "bigdecimal"

module Orders
  class PrepareFromCart
    Result = Struct.new(:success?, :preparation, :error_code, keyword_init: true)

    class << self
      def call(cart:)
        new(cart: cart).call
      end
    end

    def initialize(cart:)
      @cart = cart
    end

    def call
      return Result.new(success?: false, error_code: :invalid_payload) unless @cart&.finished?

      items = @cart.cart_items.includes(:product).order(created_at: :asc, id: :asc)
      return Result.new(success?: false, error_code: :invalid_payload) if items.none?

      subtotal = BigDecimal("0")
      serialized_items = items.map do |item|
        unit_price = item.product.price
        line_subtotal = unit_price * item.quantity
        subtotal += line_subtotal

        {
          product_id: item.product_id,
          quantity: item.quantity,
          unit_price: format("%.2f", unit_price),
          line_subtotal: format("%.2f", line_subtotal),
        }
      end

      Result.new(
        success?: true,
        preparation: {
          source_cart_id: @cart.id,
          payment_method: "wallet",
          currency: "BRL",
          total_items: items.sum(&:quantity),
          subtotal: format("%.2f", subtotal),
          prepared_at: Time.current.utc.iso8601,
          items: serialized_items,
        }
      )
    rescue StandardError
      Result.new(success?: false, error_code: :invalid_payload)
    end
  end
end
