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
      return Result.new(success?: false, error_code: :invalid_payload) unless @cart.is_a?(Cart)

      items = @cart.cart_items.includes(:product).order(created_at: :asc, id: :asc)
      return Result.new(success?: false, error_code: :invalid_payload) if items.none?

      subtotal_cents = 0
      serialized_items = items.map do |item|
        product = item.product
        return Result.new(success?: false, error_code: :invalid_payload) unless product

        unit_price_cents = decimal_to_cents(product.price)
        line_subtotal_cents = unit_price_cents * item.quantity
        subtotal_cents += line_subtotal_cents

        {
          product_id: item.product_id,
          seller_id: product.user_id,
          product_title: product.title,
          quantity: item.quantity,
          unit_price_cents: unit_price_cents,
          unit_price: cents_to_decimal(unit_price_cents),
          line_subtotal_cents: line_subtotal_cents,
          line_subtotal: cents_to_decimal(line_subtotal_cents),
        }
      end
      seller_groups = build_seller_groups(items: serialized_items)

      Result.new(
        success?: true,
        preparation: {
          source_cart_id: @cart.id,
          payment_method: "wallet",
          currency: "BRL",
          total_items: items.sum(&:quantity),
          subtotal_cents: subtotal_cents,
          subtotal: cents_to_decimal(subtotal_cents),
          prepared_at: Time.current.utc.iso8601,
          items: serialized_items,
          seller_groups: seller_groups,
        }
      )
    rescue StandardError
      Result.new(success?: false, error_code: :invalid_payload)
    end

    private

    def build_seller_groups(items:)
      items.group_by { |item| item[:seller_id] }.map do |seller_id, grouped_items|
        subtotal_cents = grouped_items.sum { |item| item[:line_subtotal_cents] }

        {
          seller_id: seller_id,
          total_items: grouped_items.sum { |item| item[:quantity] },
          subtotal_cents: subtotal_cents,
          subtotal: cents_to_decimal(subtotal_cents),
          items: grouped_items,
        }
      end.sort_by { |group| group[:seller_id] }
    end

    def decimal_to_cents(value)
      (BigDecimal(value.to_s) * 100).to_i
    end

    def cents_to_decimal(value)
      format("%.2f", BigDecimal(value.to_s) / 100)
    end
  end
end
