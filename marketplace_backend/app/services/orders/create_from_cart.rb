module Orders
  class CreateFromCart
    Result = Struct.new(:success?, :orders, :summary, :error_code, keyword_init: true)

    class << self
      def call(cart:, buyer:)
        new(cart: cart, buyer: buyer).call
      end
    end

    def initialize(cart:, buyer:)
      @cart = cart
      @buyer = buyer
    end

    def call
      return Result.new(success?: false, error_code: :invalid_payload) unless valid_input?

      preparation_result = Orders::PrepareFromCart.call(cart: @cart)
      return Result.new(success?: false, error_code: preparation_result.error_code) unless preparation_result.success?

      payload = nil

      ActiveRecord::Base.transaction do
        preparation = preparation_result.preparation
        product_rows = lock_products_for(preparation)
        unless stock_available_for?(preparation:, product_rows:)
          raise ActiveRecord::Rollback
        end

        orders = create_orders_from(preparation:)
        decrement_stock!(preparation:, product_rows:)

        payload = {
          orders: orders,
          summary: build_summary(preparation:, orders:),
        }
      end

      return Result.new(success?: false, error_code: :invalid_payload) unless payload

      Result.new(success?: true, orders: payload[:orders], summary: payload[:summary])
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      Result.new(success?: false, error_code: :invalid_payload)
    end

    private

    def valid_input?
      @cart.is_a?(Cart) && @buyer.is_a?(User) && @cart.user_id == @buyer.id
    end

    def lock_products_for(preparation)
      product_ids = preparation[:items].map { |item| item[:product_id] }.uniq.sort
      Product.where(id: product_ids).order(:id).lock.index_by(&:id)
    end

    def stock_available_for?(preparation:, product_rows:)
      preparation[:items].all? do |item|
        product = product_rows[item[:product_id]]
        product.present? &&
          product.user_id == item[:seller_id] &&
          product.deleted_at.nil? &&
          product.active? &&
          product.stock_quantity >= item[:quantity]
      end
    end

    def create_orders_from(preparation:)
      preparation[:seller_groups].map do |group|
        order = Order.create!(
          user: @buyer,
          seller_id: group[:seller_id],
          source_cart: @cart,
          status: :paid,
          currency: preparation[:currency],
          total_items: group[:total_items],
          subtotal_cents: group[:subtotal_cents]
        )

        group[:items].each do |item|
          OrderItem.create!(
            order: order,
            product_id: item[:product_id],
            seller_id: item[:seller_id],
            product_title: item[:product_title],
            quantity: item[:quantity],
            unit_price_cents: item[:unit_price_cents],
            line_subtotal_cents: item[:line_subtotal_cents]
          )
        end

        order
      end
    end

    def decrement_stock!(preparation:, product_rows:)
      preparation[:items].each do |item|
        product = product_rows.fetch(item[:product_id])
        product.update!(stock_quantity: product.stock_quantity - item[:quantity])
      end
    end

    def build_summary(preparation:, orders:)
      {
        orders_count: orders.length,
        order_ids: orders.map(&:id),
        total_items: preparation[:total_items],
        subtotal_cents: preparation[:subtotal_cents],
        subtotal: preparation[:subtotal],
        currency: preparation[:currency],
        payment_method: preparation[:payment_method],
      }
    end
  end
end
