module Carts
  class UpdateItem
    Result = Struct.new(:success?, :cart, :error_code, keyword_init: true)

    ALLOWED_KEYS = %i[quantity price].freeze

    class << self
      def call(user:, cart_item_id:, params:)
        new(user: user, cart_item_id: cart_item_id, params: params).call
      end
    end

    def initialize(user:, cart_item_id:, params:)
      @user = user
      @cart_item_id = cart_item_id
      @params = (params || {}).to_h.deep_symbolize_keys
    end

    def call
      return Result.new(success?: false, error_code: :invalid_payload) unless @user
      return Result.new(success?: false, error_code: :invalid_payload) unless valid_keys?

      requested_quantity = normalize_quantity(@params[:quantity])
      return Result.new(success?: false, error_code: :invalid_payload) unless requested_quantity

      cart = CartFinder.active_cart_for(user: @user)
      return Result.new(success?: false, error_code: :not_found) unless cart

      cart_item = find_cart_item(cart)
      return Result.new(success?: false, error_code: :not_found) unless cart_item

      product = Product.not_deleted.where(active: true).find_by(id: cart_item.product_id)
      return Result.new(success?: false, error_code: :invalid_payload) unless product

      final_quantity = [requested_quantity, product.stock_quantity].min
      return Result.new(success?: false, error_code: :invalid_payload) if final_quantity < 1

      return Result.new(success?: false, error_code: :invalid_payload) unless cart_item.update(quantity: final_quantity)

      Result.new(success?: true, cart: cart.reload)
    rescue StandardError
      Result.new(success?: false, error_code: :invalid_payload)
    end

    private

    def valid_keys?
      return false if @params.empty?
      return false unless @params.key?(:quantity)

      (@params.keys - ALLOWED_KEYS).empty?
    end

    def normalize_quantity(value)
      return nil unless value.is_a?(Integer)
      return nil if value < 1 || value > 999_999

      value
    end

    def find_cart_item(cart)
      cart.cart_items.find_by(id: @cart_item_id)
    rescue ActiveRecord::StatementInvalid
      nil
    end
  end
end
