class Cart < ApplicationRecord
  belongs_to :user

  enum :status,
       {
         active: "active",
         finished: "finished",
         abandoned: "abandoned",
       },
       default: :active,
       validate: true

  validates :user_id, presence: true
  validates :user_id, uniqueness: { conditions: -> { where(status: "active") } }, if: :active?

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }
end
