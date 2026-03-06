class RefreshSession < ApplicationRecord
  belongs_to :user

  validates :refresh_jti, presence: true, uniqueness: true
  validates :refresh_token_hash, presence: true
  validates :expires_at, presence: true

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }

  def revoked?
    revoked_at.present?
  end

  def expired?(reference_time = Time.current)
    expires_at <= reference_time
  end

  def active?(reference_time = Time.current)
    !revoked? && !expired?(reference_time)
  end
end
