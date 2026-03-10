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
  belongs_to :checkout_group
  has_many :order_items, dependent: :destroy
  has_many :order_transitions, -> { order(position: :asc, created_at: :asc, id: :asc) }, dependent: :destroy
  has_one :seller_receivable, dependent: :destroy

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
  validate :checkout_group_matches_order_context
  validate :status_change_requires_workflow, on: :update

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }

  def sync_status_from_workflow!(new_status)
    @allow_workflow_status_sync = true
    update!(status: new_status)
  ensure
    @allow_workflow_status_sync = false
  end

  def participant?(user)
    user.is_a?(User) && [user_id, seller_id].include?(user.id)
  end

  private

  def seller_cannot_match_buyer
    return unless user_id.present? && seller_id.present?
    return unless user_id == seller_id

    errors.add(:seller_id, "must differ from buyer")
  end

  def checkout_group_matches_order_context
    return unless checkout_group

    errors.add(:checkout_group_id, "must belong to buyer") if checkout_group.buyer_id != user_id
    errors.add(:checkout_group_id, "must reference the same source cart") if checkout_group.source_cart_id != source_cart_id
  end

  def status_change_requires_workflow
    return unless will_save_change_to_status?
    return if @allow_workflow_status_sync

    errors.add(:status, "must be changed through workflow")
  end
end
