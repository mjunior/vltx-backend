module Orders
  class ApplyTransition
    Result = Struct.new(:success?, :order, :transition, :error_code, keyword_init: true)

    class << self
      def call(order:, actor:, action:, metadata: {})
        new(order:, actor:, action:, metadata:).call
      end
    end

    def initialize(order:, actor:, action:, metadata:)
      @order = order
      @actor = actor
      @action = action.to_s
      @metadata = metadata || {}
    end

    def call
      return Result.new(success?: false, error_code: :invalid_payload) unless valid_input?

      transition = nil

      Order.transaction do
        locked_order = Order.lock.includes(:order_transitions).find(@order.id)
        actor_role = role_for(locked_order, @actor)
        return Result.new(success?: false, error_code: :not_found) unless actor_role

        target_status = next_status_for(order: locked_order, actor_role:)
        return Result.new(success?: false, error_code: :invalid_transition) unless target_status

        transition = Orders::TransitionRecorder.record!(
          order: locked_order,
          to_status: target_status,
          action: @action,
          actor: @actor,
          actor_role: actor_role,
          metadata: normalized_metadata(actor_role:)
        ).order_transitions.timeline.last

        @order = locked_order
      end

      Result.new(success?: true, order: @order, transition: transition)
    end

    private

    def valid_input?
      @order.is_a?(Order) && @actor.is_a?(User) && @action.present? && @metadata.is_a?(Hash)
    end

    def role_for(order, actor)
      return OrderTransition::ACTOR_ROLES[:buyer] if order.user_id == actor.id
      return OrderTransition::ACTOR_ROLES[:seller] if order.seller_id == actor.id

      nil
    end

    def next_status_for(order:, actor_role:)
      case [actor_role, @action, order.status]
      when [OrderTransition::ACTOR_ROLES[:seller], "advance", Order::STATUSES[:paid]]
        Order::STATUSES[:in_separation]
      when [OrderTransition::ACTOR_ROLES[:seller], "advance", Order::STATUSES[:in_separation]]
        Order::STATUSES[:confirmed]
      when [OrderTransition::ACTOR_ROLES[:buyer], "cancel", Order::STATUSES[:paid]]
        Order::STATUSES[:canceled]
      when [OrderTransition::ACTOR_ROLES[:buyer], "deliver", Order::STATUSES[:confirmed]]
        Order::STATUSES[:delivered]
      when [OrderTransition::ACTOR_ROLES[:buyer], "contest", Order::STATUSES[:delivered]]
        Order::STATUSES[:contested]
      else
        nil
      end
    end

    def normalized_metadata(actor_role:)
      @metadata.deep_stringify_keys.merge(
        "actor_id" => @actor.id,
        "actor_role" => actor_role,
        "action" => @action
      )
    end
  end
end
