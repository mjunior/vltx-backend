class Wallet < ApplicationRecord
  INITIAL_CREDIT_CENTS = 10_00
  INITIAL_CREDIT_REFERENCE_TYPE = "wallet_initial_credit".freeze

  belongs_to :user
  has_many :wallet_transactions, dependent: :restrict_with_exception

  after_create :grant_initial_credit!

  validates :user_id, presence: true, uniqueness: true
  validates :current_balance_cents,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0,
            }

  private

  def grant_initial_credit!
    result = Wallets::Operations::ApplyMovement.call(
      wallet: self,
      transaction_type: :credit,
      trusted_amount_cents: INITIAL_CREDIT_CENTS,
      reference_type: INITIAL_CREDIT_REFERENCE_TYPE,
      reference_id: id,
      operation_key: "wallet-initial-credit:#{id}",
      metadata: {
        "source" => "wallet_creation",
        "reason" => "initial_credit",
        "note" => "R$10 credit on wallet creation"
      }
    )

    return if result.success?

    errors.add(:base, "failed to grant initial credit")
    raise ActiveRecord::RecordInvalid.new(self)
  end
end
