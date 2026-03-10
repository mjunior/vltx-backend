class SellerReceivable < ApplicationRecord
  STATUSES = {
    pending: "pending",
    reversed: "reversed",
    credited: "credited",
  }.freeze

  belongs_to :order
  belongs_to :seller, class_name: "User"
  belongs_to :buyer, class_name: "User"
  belongs_to :checkout_group

  enum :status, STATUSES, default: :pending, validate: true

  validates :amount_cents,
            numericality: {
              only_integer: true,
              greater_than: 0,
            }
  validates :order_id, uniqueness: true
  validate :seller_cannot_match_buyer
  validate :order_context_must_match

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }

  private

  def seller_cannot_match_buyer
    return unless seller_id.present? && buyer_id.present?
    return unless seller_id == buyer_id

    errors.add(:seller_id, "must differ from buyer")
  end

  def order_context_must_match
    return unless order

    errors.add(:seller_id, "must match order seller") if seller_id != order.seller_id
    errors.add(:buyer_id, "must match order buyer") if buyer_id != order.user_id
    errors.add(:checkout_group_id, "must match order checkout group") if checkout_group_id != order.checkout_group_id
  end
end
