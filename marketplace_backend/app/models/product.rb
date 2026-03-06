class Product < ApplicationRecord
  belongs_to :user

  scope :not_deleted, -> { where(deleted_at: nil) }

  validates :title, presence: true, length: { minimum: 3, maximum: 120 }
  validates :description, presence: true, length: { minimum: 10, maximum: 2000 }
  validates :price, presence: true,
                    numericality: {
                      greater_than: 0,
                      less_than_or_equal_to: 9_999_999,
                    }
  validates :stock_quantity, presence: true,
                             numericality: {
                               only_integer: true,
                               greater_than_or_equal_to: 0,
                               less_than_or_equal_to: 999_999,
                             }
  validates :active, inclusion: { in: [true, false] }
end
