class OrderTransition < ApplicationRecord
  ACTOR_ROLES = {
    buyer: "buyer",
    seller: "seller",
    system: "system",
  }.freeze

  belongs_to :order
  belongs_to :actor, class_name: "User", optional: true

  enum :actor_role, ACTOR_ROLES, validate: true

  validates :action, presence: true, length: { maximum: 64 }
  validates :position,
            numericality: {
              only_integer: true,
              greater_than: 0,
            },
            uniqueness: { scope: :order_id }
  validates :to_status, inclusion: { in: Order::STATUSES.values }
  validates :from_status, inclusion: { in: Order::STATUSES.values }, allow_nil: true
  validate :actor_presence_matches_role
  validate :metadata_must_be_hash

  scope :timeline, -> { order(position: :asc, created_at: :asc, id: :asc) }

  private

  def actor_presence_matches_role
    return unless actor_role.present?
    return if system? && actor_id.nil?
    return if !system? && actor_id.present?

    errors.add(:actor_id, "must match actor role")
  end

  def metadata_must_be_hash
    return if metadata.is_a?(Hash)

    errors.add(:metadata, "must be an object")
  end
end
