require "bigdecimal"

module SellerReceivables
  class ReadSummary
    Result = Struct.new(:success?, :summary, :error_code, keyword_init: true)

    class << self
      def call(seller:)
        new(seller: seller).call
      end
    end

    def initialize(seller:)
      @seller = seller
    end

    def call
      return Result.new(success?: false, error_code: :invalid_payload) unless @seller.is_a?(User)

      receivables = SellerReceivable.includes(:order, :buyer, :checkout_group)
                                     .where(seller_id: @seller.id)
                                     .recent_first
      pending_total_cents = receivables.select(&:pending?).sum(&:amount_cents)

      Result.new(
        success?: true,
        summary: {
          seller_id: @seller.id,
          pending_total_cents: pending_total_cents,
          pending_total: cents_to_decimal_string(pending_total_cents),
          receivables: receivables.map { |receivable| serialize_receivable(receivable) },
        }
      )
    rescue StandardError
      Result.new(success?: false, error_code: :invalid_payload)
    end

    private

    def serialize_receivable(receivable)
      {
        id: receivable.id,
        order_id: receivable.order_id,
        checkout_group_id: receivable.checkout_group_id,
        buyer_id: receivable.buyer_id,
        amount_cents: receivable.amount_cents,
        amount: cents_to_decimal_string(receivable.amount_cents),
        status: receivable.status,
        created_at: receivable.created_at,
      }
    end

    def cents_to_decimal_string(cents)
      format("%.2f", BigDecimal(cents) / 100)
    end
  end
end
