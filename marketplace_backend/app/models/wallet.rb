class Wallet < ApplicationRecord
  belongs_to :user
  has_many :wallet_transactions, dependent: :restrict_with_exception

  validates :user_id, presence: true, uniqueness: true
  validates :current_balance_cents,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0,
            }
end
