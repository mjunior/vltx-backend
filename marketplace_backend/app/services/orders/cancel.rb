module Orders
  class Cancel
    Result = Struct.new(:success?, :order, :refund_transaction, :error_code, keyword_init: true)

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
        locked_order = Order.lock.includes(:order_items, :seller_receivable).find(@order.id)
        return Result.new(success?: false, error_code: :not_found) unless locked_order.user_id == @actor.id

        if locked_order.canceled?
          payload = { order: locked_order, refund_transaction: existing_refund_for(locked_order) }
          next
        end

        transition = Orders::ApplyTransition.call(
          order: locked_order,
          actor: @actor,
          action: :cancel,
          metadata: { "source" => "buyer_cancel" }
        )
        return Result.new(success?: false, error_code: transition.error_code) unless transition.success?

        restore_stock_for!(locked_order)
        reverse_receivable_for!(locked_order)
        refund_result = refund_buyer_for!(locked_order)

        payload = {
          order: locked_order.reload,
          refund_transaction: refund_result.transaction
        }
      end

      Result.new(success?: true, order: payload[:order], refund_transaction: payload[:refund_transaction])
    end

    private

    def valid_input?
      @order.is_a?(Order) && @actor.is_a?(User)
    end

    def restore_stock_for!(order)
      grouped_items = order.order_items.group_by(&:product_id)
      products = Product.where(id: grouped_items.keys.sort).order(:id).lock.index_by(&:id)

      grouped_items.each do |product_id, items|
        quantity_to_restore = items.sum(&:quantity)
        product = products.fetch(product_id)
        product.update!(stock_quantity: product.stock_quantity + quantity_to_restore)
      end
    end

    def reverse_receivable_for!(order)
      receivable = order.seller_receivable
      return unless receivable
      return if receivable.reversed?

      receivable.update!(status: :reversed)
    end

    def refund_buyer_for!(order)
      wallet = Wallet.find_or_create_by!(user: order.user)
      result = Wallets::Operations::ApplyMovement.call(
        wallet: wallet,
        transaction_type: :refund,
        trusted_amount_cents: order.subtotal_cents,
        reference_type: "order",
        reference_id: order.id,
        operation_key: "order-refund:#{order.id}",
        metadata: {
          "order_id" => order.id,
          "reason" => "order_canceled",
          "source" => "order_cancel"
        }
      )

      raise ActiveRecord::Rollback unless result.success?

      result
    end

    def existing_refund_for(order)
      wallet = Wallet.find_by(user_id: order.user_id)
      return nil unless wallet

      wallet.wallet_transactions.find_by(transaction_type: :refund, reference_type: "order", reference_id: order.id)
    end
  end
end
