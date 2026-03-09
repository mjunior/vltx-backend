class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product
  belongs_to :seller, class_name: "User"

  validates :product_title, presence: true, length: { minimum: 3, maximum: 120 }
  validates :quantity,
            numericality: {
              only_integer: true,
              greater_than: 0,
              less_than_or_equal_to: 999_999,
            }
  validates :unit_price_cents,
            numericality: {
              only_integer: true,
              greater_than: 0,
            }
  validates :line_subtotal_cents,
            numericality: {
              only_integer: true,
              greater_than: 0,
            }
  validates :product_id, uniqueness: { scope: :order_id }
  validate :seller_matches_order
  validate :line_subtotal_matches_quantity

  private

  def seller_matches_order
    return unless seller_id.present? && order
    return if seller_id == order.seller_id

    errors.add(:seller_id, "must match order seller")
  end

  def line_subtotal_matches_quantity
    return unless quantity.is_a?(Integer) && unit_price_cents.is_a?(Integer) && line_subtotal_cents.is_a?(Integer)
    return if (quantity * unit_price_cents) == line_subtotal_cents

    errors.add(:line_subtotal_cents, "must match quantity times unit price")
  end
end
