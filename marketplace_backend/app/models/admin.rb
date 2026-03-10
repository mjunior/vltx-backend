class Admin < ApplicationRecord
  has_secure_password

  has_many :admin_refresh_sessions, dependent: :destroy

  before_validation :normalize_email

  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 8 }, if: :password_validation_required?

  scope :active, -> { where(active: true) }

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def password_validation_required?
    new_record? || password.present?
  end
end
