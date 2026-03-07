require "test_helper"
require "securerandom"

class CartTest < ActiveSupport::TestCase
  def create_user(email: "cart-model@example.com")
    Users::Create.call(
      email: email,
      password: "password123",
      password_confirmation: "password123"
    ).user
  end

  test "allows multiple carts for same user when only one is active" do
    user = create_user

    active_cart = Cart.create!(user: user, status: :active)
    finished_cart = Cart.create!(user: user, status: :finished)

    assert active_cart.persisted?
    assert finished_cart.persisted?
    assert_equal 1, user.carts.active.count
  end

  test "rejects invalid status" do
    user = create_user(email: "cart-invalid-status@example.com")

    cart = Cart.new(user: user, status: "invalid")

    assert_not cart.valid?
    assert_includes cart.errors[:status], "is not included in the list"
  end

  test "partial unique index blocks second active cart for same user" do
    user = create_user(email: "cart-unique-index@example.com")
    Cart.create!(user: user, status: :active)

    assert_raises(ActiveRecord::RecordNotUnique) do
      Cart.insert_all!([
                         {
                           id: SecureRandom.uuid,
                           user_id: user.id,
                           status: "active",
                           created_at: Time.current,
                           updated_at: Time.current,
                         },
                       ])
    end
  end
end
