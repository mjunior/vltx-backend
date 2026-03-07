module Carts
  class CartSerializer
    class << self
      def call(cart:)
        {
          id: cart.id,
          created_at: cart.created_at,
          updated_at: cart.updated_at,
          total_items: 0,
          subtotal: "0.00",
        }
      end
    end
  end
end
