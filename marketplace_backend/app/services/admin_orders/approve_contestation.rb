module AdminOrders
  class ApproveContestation
    Result = Struct.new(:success?, :order, :buyer_refund_transaction, :seller_reversal_transaction, :error_code, keyword_init: true)

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

      payload = nil
      failure_code = nil

      Order.transaction do
        locked_order = Order.lock.includes(:seller_receivable).find_by(id: @order_id)
        return Result.new(success?: false, error_code: :not_found) unless locked_order

        if locked_order.refunded?
          payload = {
            order: locked_order,
            buyer_refund_transaction: existing_buyer_refund_for(locked_order),
            seller_reversal_transaction: existing_seller_reversal_for(locked_order)
          }
          next
        end

        unless locked_order.contested?
          failure_code = :invalid_payload
          raise ActiveRecord::Rollback
        end

        Orders::TransitionRecorder.record!(
          order: locked_order,
          to_status: Order::STATUSES[:refunded],
          action: :approve_contest,
          actor: nil,
          actor_role: OrderTransition::ACTOR_ROLES[:system],
          metadata: admin_metadata(action: "approve_contest")
        )

        receivable = locked_order.seller_receivable
        unless receivable&.credited?
          failure_code = :invalid_payload
          raise ActiveRecord::Rollback
        end

        buyer_wallet = Wallet.find_or_create_by!(user: locked_order.user)
        seller_wallet = Wallet.find_or_create_by!(user: locked_order.seller)
        lock_wallets!(buyer_wallet, seller_wallet)

        seller_reversal = reverse_seller_credit_for!(locked_order, seller_wallet)
        unless seller_reversal.success?
          failure_code = seller_reversal.error_code
          raise ActiveRecord::Rollback
        end

        buyer_refund = refund_buyer_for!(locked_order, buyer_wallet)
        unless buyer_refund.success?
          failure_code = buyer_refund.error_code
          raise ActiveRecord::Rollback
        end

        receivable.update!(status: :reversed)

        payload = {
          order: locked_order.reload,
          buyer_refund_transaction: buyer_refund.transaction,
          seller_reversal_transaction: seller_reversal.transaction
        }
      end

      return Result.new(success?: false, error_code: failure_code || :invalid_payload) unless payload

      Result.new(
        success?: true,
        order: payload[:order],
        buyer_refund_transaction: payload[:buyer_refund_transaction],
        seller_reversal_transaction: payload[:seller_reversal_transaction]
      )
    rescue StandardError
      Result.new(success?: false, error_code: :invalid_payload)
    end

    private

    def admin_metadata(action:)
      {
        "source" => "admin_order_resolution",
        "admin_id" => @admin.id,
        "admin_email" => @admin.email,
        "action" => action
      }
    end

    def lock_wallets!(*wallets)
      wallet_ids = wallets.map(&:id).uniq.sort
      Wallet.where(id: wallet_ids).order(:id).lock.load
    end

    def reverse_seller_credit_for!(order, wallet)
      Wallets::Operations::ApplyMovement.call(
        wallet: wallet,
        transaction_type: :debit,
        trusted_amount_cents: order.subtotal_cents,
        reference_type: "order_contest_resolution",
        reference_id: order.id,
        operation_key: "seller-order-contest-debit:#{order.id}",
        metadata: {
          "order_id" => order.id,
          "reason" => "contest_approved",
          "source" => "admin_approve_contest"
        }
      )
    end

    def refund_buyer_for!(order, wallet)
      Wallets::Operations::ApplyMovement.call(
        wallet: wallet,
        transaction_type: :refund,
        trusted_amount_cents: order.subtotal_cents,
        reference_type: "order_contest_resolution",
        reference_id: order.id,
        operation_key: "buyer-order-contest-refund:#{order.id}",
        metadata: {
          "order_id" => order.id,
          "reason" => "contest_approved",
          "source" => "admin_approve_contest"
        }
      )
    end

    def existing_buyer_refund_for(order)
      wallet = Wallet.find_by(user_id: order.user_id)
      return nil unless wallet

      wallet.wallet_transactions.find_by(transaction_type: :refund, reference_type: "order_contest_resolution", reference_id: order.id)
    end

    def existing_seller_reversal_for(order)
      wallet = Wallet.find_by(user_id: order.seller_id)
      return nil unless wallet

      wallet.wallet_transactions.find_by(transaction_type: :debit, reference_type: "order_contest_resolution", reference_id: order.id)
    end
  end
end
