module Carts
  class AddItem
    Result = Struct.new(:success?, :cart, :error_code, keyword_init: true)

    ALLOWED_KEYS = %i[product_id quantity price].freeze

    class << self
      def call(user:, params:)
        new(user: user, params: params).call
      end
    end

    def initialize(user:, params:)
      @user = user
      @params = (params || {}).to_h.deep_symbolize_keys
    end

    def call
      return Result.new(success?: false, error_code: :invalid_payload) unless @user
      return Result.new(success?: false, error_code: :invalid_payload) unless valid_keys?

      product = fetch_product(@params[:product_id])
      return Result.new(success?: false, error_code: :invalid_payload) unless product
      return Result.new(success?: false, error_code: :invalid_payload) if product.user_id == @user.id

      requested_quantity = normalize_quantity(@params[:quantity])
      return Result.new(success?: false, error_code: :invalid_payload) unless requested_quantity

      cart = CartFinder.active_cart_for!(user: @user)
      return Result.new(success?: false, error_code: :invalid_payload) unless cart

      updated_cart = add_or_increment_item(cart:, product:, requested_quantity:)
      return Result.new(success?: false, error_code: :invalid_payload) unless updated_cart

      Result.new(success?: true, cart: updated_cart)
    rescue StandardError
      Result.new(success?: false, error_code: :invalid_payload)
    end

    private

    def valid_keys?
      return false if @params.empty?
      return false unless (ALLOWED_KEYS & @params.keys).include?(:product_id)
      return false unless (ALLOWED_KEYS & @params.keys).include?(:quantity)

      (@params.keys - ALLOWED_KEYS).empty?
    end

    def fetch_product(product_id)
      return nil if product_id.blank?

      Product.not_deleted.where(active: true).find_by(id: product_id)
    rescue ActiveRecord::StatementInvalid
      nil
    end

    def normalize_quantity(value)
      return nil unless value.is_a?(Integer)
      return nil if value < 1 || value > 999_999

      value
    end

    def add_or_increment_item(cart:, product:, requested_quantity:)
      CartItem.transaction do
        cart_item = cart.cart_items.lock.find_or_initialize_by(product_id: product.id)
        final_quantity = [target_quantity(cart_item:, requested_quantity:), product.stock_quantity].min
        return nil if final_quantity < 1

        cart_item.quantity = final_quantity
        return nil unless cart_item.save

        cart.reload
      end
    rescue ActiveRecord::RecordNotUnique
      cart.reload
    end

    def target_quantity(cart_item:, requested_quantity:)
      return requested_quantity unless cart_item.persisted?

      cart_item.quantity + requested_quantity
    end
  end
end
