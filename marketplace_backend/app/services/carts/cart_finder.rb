module Carts
  class CartFinder
    class << self
      def active_cart_for(user:)
        return nil unless user

        user.carts.active.recent_first.first
      end

      def active_cart_for!(user:)
        active_cart_for(user:) || FindOrCreateActive.call(user: user).cart
      end
    end
  end
end
