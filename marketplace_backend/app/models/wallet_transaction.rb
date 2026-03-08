class WalletTransaction < ApplicationRecord
  TRANSACTION_TYPES = {
    credit: "credit",
    debit: "debit",
    refund: "refund",
  }.freeze

  ALLOWED_METADATA_KEYS = %w[source reason order_id cart_id checkout_id note].freeze

  belongs_to :wallet

  enum :transaction_type, TRANSACTION_TYPES, validate: true

  before_update :raise_read_only_record
  before_destroy :raise_read_only_record

  validates :amount_cents,
            numericality: {
              only_integer: true,
              greater_than: 0,
            }
  validates :balance_after_cents,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0,
            }
  validates :reference_type, presence: true, length: { maximum: 64 }
  validates :reference_id, presence: true, length: { maximum: 128 }
  validates :operation_key, presence: true, length: { maximum: 128 }, uniqueness: { scope: :wallet_id }
  validate :metadata_must_be_hash
  validate :metadata_keys_allowed

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }

  private

  def metadata_must_be_hash
    return if metadata.is_a?(Hash)

    errors.add(:metadata, "must be an object")
  end

  def metadata_keys_allowed
    return unless metadata.is_a?(Hash)

    invalid_keys = metadata.keys.map(&:to_s) - ALLOWED_METADATA_KEYS
    return if invalid_keys.empty?

    errors.add(:metadata, "contains unsupported keys: #{invalid_keys.join(', ')}")
  end

  def raise_read_only_record
    raise ActiveRecord::ReadOnlyRecord, "wallet_transactions is append-only"
  end
end
