require "test_helper"

class AdminRefreshSessionTest < ActiveSupport::TestCase
  def create_admin(email: "session-admin@example.com")
    Admin.create!(email: email, password: "password123", password_confirmation: "password123")
  end

  test "is active when not revoked and not expired" do
    session = AdminRefreshSession.create!(
      admin: create_admin,
      refresh_jti: "admin-jti-1",
      refresh_token_hash: "digest-1",
      expires_at: 1.day.from_now
    )

    assert session.active?
  end

  test "is not active when revoked" do
    session = AdminRefreshSession.create!(
      admin: create_admin(email: "revoked-admin@example.com"),
      refresh_jti: "admin-jti-2",
      refresh_token_hash: "digest-2",
      expires_at: 1.day.from_now,
      revoked_at: Time.current
    )

    assert_not session.active?
  end
end
