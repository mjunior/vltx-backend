module Orders
  class OrderSerializer
    class << self
      def call(order:, viewer:)
        {
          id: order.id,
          buyer_id: order.user_id,
          seller_id: order.seller_id,
          checkout_group_id: order.checkout_group_id,
          status: order.status,
          total_items: order.total_items,
          subtotal_cents: order.subtotal_cents,
          subtotal: format("%.2f", order.subtotal_cents / 100.0),
          currency: order.currency,
          actor_role: actor_role_for(order:, viewer:),
          created_at: order.created_at,
          updated_at: order.updated_at,
          items: order.order_items.order(:created_at, :id).map { |item| Orders::OrderItemSerializer.call(order_item: item) },
          transitions: order.order_transitions.timeline.map { |transition| Orders::OrderTransitionSerializer.call(transition:) }
        }
      end

      private

      def actor_role_for(order:, viewer:)
        return "buyer" if order.user_id == viewer.id
        return "seller" if order.seller_id == viewer.id

        nil
      end
    end
  end
end
