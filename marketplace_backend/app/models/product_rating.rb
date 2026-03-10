class ProductRating < ApplicationRecord
  belongs_to :order
  belongs_to :order_item
  belongs_to :buyer, class_name: "User"
  belongs_to :product

  validates :score, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }
  validates :comment, presence: true, length: { minimum: 3, maximum: 1_000 }
  validates :order_item_id, uniqueness: true
  validate :rating_context_matches_order_item

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }

  private

  def rating_context_matches_order_item
    return unless order_item

    errors.add(:order_id, "must match order item order") if order_id != order_item.order_id
    errors.add(:buyer_id, "must match order buyer") if buyer_id != order_item.order.user_id
    errors.add(:product_id, "must match order item product") if product_id != order_item.product_id
    errors.add(:order_item_id, "must belong to delivered purchase") unless delivered_purchase?(order_item.order)
  end

  def delivered_purchase?(order)
    order.delivered_purchase?
  end
end
