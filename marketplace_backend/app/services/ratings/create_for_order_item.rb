module Ratings
  class CreateForOrderItem
    Result = Struct.new(:success?, :product_rating, :seller_rating, :error_code, keyword_init: true)

    class << self
      def call(order_item:, buyer:, score:, comment:)
        new(order_item:, buyer:, score:, comment:).call
      end
    end

    def initialize(order_item:, buyer:, score:, comment:)
      @order_item = order_item
      @buyer = buyer
      @score = score
      @comment = comment.to_s.strip
    end

    def call
      return Result.new(success?: false, error_code: :invalid_payload) unless valid_input?

      payload = nil

      ActiveRecord::Base.transaction do
        locked_item = OrderItem.lock.includes(:order, :product_rating, :seller_rating).find(@order_item.id)
        return Result.new(success?: false, error_code: :not_found) unless locked_item.order.user_id == @buyer.id
        return Result.new(success?: false, error_code: :invalid_payload) if locked_item.product_rating || locked_item.seller_rating
        return Result.new(success?: false, error_code: :invalid_transition) unless delivered_purchase?(locked_item.order)

        product_rating = ProductRating.create!(
          order: locked_item.order,
          order_item: locked_item,
          buyer: @buyer,
          product: locked_item.product,
          score: @score,
          comment: @comment
        )

        seller_rating = SellerRating.create!(
          order: locked_item.order,
          order_item: locked_item,
          buyer: @buyer,
          seller: locked_item.seller,
          score: @score,
          comment: @comment
        )

        payload = { product_rating: product_rating, seller_rating: seller_rating }
      end

      Result.new(success?: true, product_rating: payload[:product_rating], seller_rating: payload[:seller_rating])
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      Result.new(success?: false, error_code: :invalid_payload)
    end

    private

    def valid_input?
      @order_item.is_a?(OrderItem) &&
        @buyer.is_a?(User) &&
        @score.is_a?(Integer) &&
        @score.between?(1, 5) &&
        @comment.present?
    end

    def delivered_purchase?(order)
      order.delivered_purchase?
    end
  end
end
