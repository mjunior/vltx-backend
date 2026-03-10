module Orders
  class OrderTransitionSerializer
    class << self
      def call(transition:)
        {
          id: transition.id,
          action: transition.action,
          actor_id: transition.actor_id,
          actor_role: transition.actor_role,
          from_status: transition.from_status,
          to_status: transition.to_status,
          created_at: transition.created_at
        }
      end
    end
  end
end
