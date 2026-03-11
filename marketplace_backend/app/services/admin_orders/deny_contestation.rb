module AdminOrders
  class DenyContestation
    Result = Struct.new(:success?, :order, :error_code, keyword_init: true)

    class << self
      def call(order_id:, admin:)
        new(order_id: order_id, admin: admin).call
      end
    end

    def initialize(order_id:, admin:)
      @order_id = order_id
      @admin = admin
    end

    def call
      return Result.new(success?: false, error_code: :invalid_payload) unless @admin.is_a?(Admin)

      order = Order.lock.includes(:order_transitions).find_by(id: @order_id)
      return Result.new(success?: false, error_code: :not_found) unless order

      if order.delivered?
        deny_transition = order.order_transitions.where(action: "deny_contest", to_status: Order::STATUSES[:delivered]).exists?
        return Result.new(success?: true, order: order) if deny_transition
      end

      return Result.new(success?: false, error_code: :invalid_payload) unless order.contested?

      Orders::TransitionRecorder.record!(
        order: order,
        to_status: Order::STATUSES[:delivered],
        action: :deny_contest,
        actor: nil,
        actor_role: OrderTransition::ACTOR_ROLES[:system],
        metadata: {
          "source" => "admin_order_resolution",
          "admin_id" => @admin.id,
          "admin_email" => @admin.email,
          "action" => "deny_contest"
        }
      )

      Result.new(success?: true, order: order.reload)
    rescue StandardError
      Result.new(success?: false, error_code: :invalid_payload)
    end
  end
end
