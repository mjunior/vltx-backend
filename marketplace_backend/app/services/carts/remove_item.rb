module Carts
  class RemoveItem
    Result = Struct.new(:success?, :cart, :error_code, keyword_init: true)

    class << self
      def call(user:, cart_item_id:)
        new(user: user, cart_item_id: cart_item_id).call
      end
    end

    def initialize(user:, cart_item_id:)
      @user = user
      @cart_item_id = cart_item_id
    end

    def call
      return Result.new(success?: false, error_code: :invalid_payload) unless @user

      cart = CartFinder.active_cart_for(user: @user)
      return Result.new(success?: false, error_code: :not_found) unless cart

      cart_item = find_cart_item(cart)
      return Result.new(success?: false, error_code: :not_found) unless cart_item

      return Result.new(success?: false, error_code: :invalid_payload) unless cart_item.destroy

      Result.new(success?: true, cart: cart.reload)
    rescue StandardError
      Result.new(success?: false, error_code: :invalid_payload)
    end

    private

    def find_cart_item(cart)
      cart.cart_items.find_by(id: @cart_item_id)
    rescue ActiveRecord::StatementInvalid
      nil
    end
  end
end
