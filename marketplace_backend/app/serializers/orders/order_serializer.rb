module Orders
  class OrderSerializer
    class << self
      def call(order:, viewer:)
        actor_role = actor_role_for(order:, viewer:)

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
          actor_role: actor_role,
          available_actions: available_actions_for(order:, actor_role:),
          created_at: order.created_at,
          updated_at: order.updated_at,
          items: order.order_items.order(:created_at, :id).map { |item| Orders::OrderItemSerializer.call(order_item: item, order: order, viewer: viewer) },
          transitions: order.order_transitions.timeline.map { |transition| Orders::OrderTransitionSerializer.call(transition:) }
        }
      end

      private

      def actor_role_for(order:, viewer:)
        return "admin" if viewer.is_a?(Admin)
        return "buyer" if order.user_id == viewer.id
        return "seller" if order.seller_id == viewer.id

        nil
      end

      def available_actions_for(order:, actor_role:)
        return {
          can_advance: false,
          can_approve_contest: false,
          can_cancel: false,
          can_refund: false,
          can_deliver: false,
          can_contest: false,
          can_rate: false
        } if actor_role == "admin"

        {
          can_advance: actor_role == "seller" && (order.paid? || order.in_separation?),
          can_approve_contest: actor_role == "seller" && order.contested?,
          can_cancel: actor_role == "buyer" && order.paid?,
          can_refund: actor_role == "buyer" && order.paid?,
          can_deliver: actor_role == "buyer" && order.confirmed?,
          can_contest: actor_role == "buyer" && order.delivered?,
          can_rate: actor_role == "buyer" && order.delivered_purchase? && order.order_items.any? { |item| item.product_rating.nil? && item.seller_rating.nil? }
        }
      end
    end
  end
end
