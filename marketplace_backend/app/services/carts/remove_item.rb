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
      if cart_item.nil?
        return inactive_item_error(cart: find_inactive_owned_cart)
      end

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

    def find_inactive_owned_cart
      Cart.joins(:cart_items)
          .where(user_id: @user.id, status: [Cart.statuses[:finished], Cart.statuses[:abandoned]])
          .where(cart_items: { id: @cart_item_id })
          .distinct
          .first
    rescue ActiveRecord::StatementInvalid
      nil
    end

    def inactive_item_error(cart:)
      return Result.new(success?: false, error_code: :not_found) unless cart

      InactiveCartAbuseGuard.track!(user: @user, cart: cart, action: "remove_item")
      Result.new(success?: false, error_code: :invalid_payload)
    end
  end
end
