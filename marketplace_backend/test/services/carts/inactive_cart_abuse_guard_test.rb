require "test_helper"

module Carts
  class InactiveCartAbuseGuardTest < ActiveSupport::TestCase
    setup do
      InactiveCartAbuseGuard.reset!
    end

    def create_user(email: "inactive-guard@example.com")
      Users::Create.call(
        email: email,
        password: "password123",
        password_confirmation: "password123"
      ).user
    end

    test "revokes all refresh sessions when threshold is reached" do
      user = create_user
      cart = Cart.create!(user: user, status: :finished)

      2.times do
        refresh = Auth::Jwt::Issuer.issue_refresh(user_id: user.id)
        Auth::Sessions::CreateSession.call(user: user, refresh_token: refresh)
      end

      assert_equal 2, user.refresh_sessions.active.count

      2.times do |attempt|
        result = InactiveCartAbuseGuard.track!(user: user, cart: cart, action: "update_item")
        assert_equal attempt + 1, result.count
        assert_not result.revoked
      end

      threshold_result = InactiveCartAbuseGuard.track!(user: user, cart: cart, action: "update_item")

      assert_equal 3, threshold_result.count
      assert threshold_result.revoked
      assert_equal 0, user.refresh_sessions.active.count
      assert_equal 2, user.refresh_sessions.where.not(revoked_at: nil).count
    end

    test "tracks counters per action key" do
      user = create_user(email: "inactive-guard-actions@example.com")
      cart = Cart.create!(user: user, status: :abandoned)

      update_result = InactiveCartAbuseGuard.track!(user: user, cart: cart, action: "update_item")
      remove_result = InactiveCartAbuseGuard.track!(user: user, cart: cart, action: "remove_item")

      assert_equal 1, update_result.count
      assert_equal 1, remove_result.count
      assert_not update_result.revoked
      assert_not remove_result.revoked
    end
  end
end
