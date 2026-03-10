class User < ApplicationRecord
  VERIFICATION_STATUSES = {
    unverified: "unverified",
    verified: "verified",
  }.freeze

  has_secure_password

  has_one :profile, dependent: :destroy
  has_many :refresh_sessions, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :carts, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :product_ratings, foreign_key: :buyer_id, dependent: :restrict_with_exception, inverse_of: :buyer
  has_many :seller_ratings, foreign_key: :buyer_id, dependent: :restrict_with_exception, inverse_of: :buyer
  has_many :seller_orders, class_name: "Order", foreign_key: :seller_id, dependent: :restrict_with_exception, inverse_of: :seller
  has_many :order_transitions, foreign_key: :actor_id, dependent: :restrict_with_exception, inverse_of: :actor
  has_many :checkout_groups, foreign_key: :buyer_id, dependent: :restrict_with_exception, inverse_of: :buyer
  has_many :seller_receivables, foreign_key: :seller_id, dependent: :restrict_with_exception, inverse_of: :seller
  has_many :buyer_receivables, class_name: "SellerReceivable", foreign_key: :buyer_id, dependent: :restrict_with_exception, inverse_of: :buyer
  has_many :received_seller_ratings, class_name: "SellerRating", foreign_key: :seller_id, dependent: :restrict_with_exception, inverse_of: :seller
  has_many :rated_products, through: :product_ratings, source: :product
  has_one :wallet, dependent: :destroy

  enum :verification_status, VERIFICATION_STATUSES, default: :unverified, validate: true

  before_validation :normalize_email

  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { case_sensitive: false }
  validates :active, inclusion: { in: [true, false] }
  validates :password, length: { minimum: 8 }, if: :password_validation_required?

  scope :active_only, -> { where(active: true) }

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def password_validation_required?
    new_record? || password.present?
  end
end
