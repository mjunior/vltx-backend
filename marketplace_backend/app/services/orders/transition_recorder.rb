module Orders
  class TransitionRecorder
    class << self
      def record!(order:, to_status:, action:, actor:, actor_role:, metadata: {})
        new(order:, to_status:, action:, actor:, actor_role:, metadata:).record!
      end
    end

    def initialize(order:, to_status:, action:, actor:, actor_role:, metadata:)
      @order = order
      @to_status = to_status.to_s
      @action = action.to_s
      @actor = actor
      @actor_role = actor_role.to_s
      @metadata = metadata || {}
    end

    def record!
      OrderTransition.create!(
        order: @order,
        actor: @actor,
        actor_role: @actor_role,
        action: @action,
        from_status: @order.status,
        to_status: @to_status,
        position: next_position,
        metadata: @metadata
      )

      @order.sync_status_from_workflow!(@to_status)
      @order
    end

    private

    def next_position
      @order.order_transitions.maximum(:position).to_i + 1
    end
  end
end
