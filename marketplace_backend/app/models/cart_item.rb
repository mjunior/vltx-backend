class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product

  validates :quantity, presence: true,
                       numericality: {
                         only_integer: true,
                         greater_than: 0,
                         less_than_or_equal_to: 999_999,
                       }
  validates :product_id, uniqueness: { scope: :cart_id }
end
