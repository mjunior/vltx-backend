class User < ApplicationRecord
  has_secure_password

  has_one :profile, dependent: :destroy
  has_many :refresh_sessions, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :carts, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :seller_orders, class_name: "Order", foreign_key: :seller_id, dependent: :restrict_with_exception, inverse_of: :seller
  has_many :checkout_groups, foreign_key: :buyer_id, dependent: :restrict_with_exception, inverse_of: :buyer
  has_many :seller_receivables, foreign_key: :seller_id, dependent: :restrict_with_exception, inverse_of: :seller
  has_many :buyer_receivables, class_name: "SellerReceivable", foreign_key: :buyer_id, dependent: :restrict_with_exception, inverse_of: :buyer
  has_one :wallet, dependent: :destroy

  before_validation :normalize_email

  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 8 }, if: :password_validation_required?

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def password_validation_required?
    new_record? || password.present?
  end
end
