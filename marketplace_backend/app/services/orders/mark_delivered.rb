module Orders
  class MarkDelivered
    Result = Struct.new(:success?, :order, :credit_transaction, :error_code, keyword_init: true)

    class << self
      def call(order:, actor:)
        new(order:, actor:).call
      end
    end

    def initialize(order:, actor:)
      @order = order
      @actor = actor
    end

    def call
      return Result.new(success?: false, error_code: :invalid_payload) unless valid_input?

      payload = nil

      Order.transaction do
        locked_order = Order.lock.includes(:seller_receivable).find(@order.id)
        return Result.new(success?: false, error_code: :not_found) unless locked_order.user_id == @actor.id

        if locked_order.delivered?
          payload = { order: locked_order, credit_transaction: existing_credit_for(locked_order) }
          next
        end

        transition = Orders::ApplyTransition.call(
          order: locked_order,
          actor: @actor,
          action: :deliver,
          metadata: { "source" => "buyer_deliver" }
        )
        return Result.new(success?: false, error_code: transition.error_code) unless transition.success?

        receivable = locked_order.seller_receivable
        return Result.new(success?: false, error_code: :invalid_payload) unless receivable&.pending?

        credit_result = credit_seller_for!(locked_order, receivable)
        payload = { order: locked_order.reload, credit_transaction: credit_result.transaction }
      end

      Result.new(success?: true, order: payload[:order], credit_transaction: payload[:credit_transaction])
    end

    private

    def valid_input?
      @order.is_a?(Order) && @actor.is_a?(User)
    end

    def credit_seller_for!(order, receivable)
      wallet = Wallet.find_or_create_by!(user: order.seller)
      result = Wallets::Operations::ApplyMovement.call(
        wallet: wallet,
        transaction_type: :credit,
        trusted_amount_cents: order.subtotal_cents,
        reference_type: "order",
        reference_id: order.id,
        operation_key: "seller-order-credit:#{order.id}",
        metadata: {
          "order_id" => order.id,
          "reason" => "seller_receivable_release",
          "source" => "order_delivered"
        }
      )

      raise ActiveRecord::Rollback unless result.success?

      receivable.update!(status: :credited)
      result
    end

    def existing_credit_for(order)
      wallet = Wallet.find_by(user_id: order.seller_id)
      return nil unless wallet

      wallet.wallet_transactions.find_by(transaction_type: :credit, reference_type: "order", reference_id: order.id)
    end
  end
end
