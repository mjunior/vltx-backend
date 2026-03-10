class CheckoutGroup < ApplicationRecord
  belongs_to :buyer, class_name: "User"
  belongs_to :source_cart, class_name: "Cart"

  has_many :orders, dependent: :restrict_with_exception
  has_many :seller_receivables, dependent: :restrict_with_exception

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
  validates :source_cart_id, uniqueness: true
  validate :buyer_must_match_source_cart_owner

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }

  private

  def buyer_must_match_source_cart_owner
    return unless buyer_id.present? && source_cart
    return if source_cart.user_id == buyer_id

    errors.add(:buyer_id, "must match source cart owner")
  end
end
