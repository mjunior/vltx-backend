class Order < ApplicationRecord
  STATUSES = {
    paid: "paid",
    in_separation: "in_separation",
    confirmed: "confirmed",
    delivered: "delivered",
    contested: "contested",
    canceled: "canceled",
  }.freeze

  belongs_to :user
  belongs_to :seller, class_name: "User"
  belongs_to :source_cart, class_name: "Cart"
  has_many :order_items, dependent: :destroy

  enum :status, STATUSES, default: :paid, validate: true

  validates :currency, presence: true, length: { is: 3 }
  validates :total_items,
            numericality: {
              only_integer: true,
              greater_than: 0,
            }
  validates :subtotal_cents,
            numericality: {
              only_integer: true,
              greater_than: 0,
            }
  validates :source_cart_id, uniqueness: { scope: :seller_id }

  validate :seller_cannot_match_buyer

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }

  private

  def seller_cannot_match_buyer
    return unless user_id.present? && seller_id.present?
    return unless user_id == seller_id

    errors.add(:seller_id, "must differ from buyer")
  end
end
