require "test_helper"

class RefreshSessionTest < ActiveSupport::TestCase
  def build_user(email: "refresh-user@example.com")
    User.create!(
      email: email,
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "is valid with required attributes" do
    user = build_user
    refresh_session = RefreshSession.new(
      user: user,
      refresh_jti: "jti-123",
      refresh_token_hash: "hash-123",
      expires_at: 1.day.from_now
    )

    assert refresh_session.valid?
  end

  test "requires refresh_jti" do
    user = build_user
    refresh_session = RefreshSession.new(
      user: user,
      refresh_token_hash: "hash-123",
      expires_at: 1.day.from_now
    )

    assert_not refresh_session.valid?
    assert_includes refresh_session.errors[:refresh_jti], "can't be blank"
  end

  test "requires unique refresh_jti" do
    user = build_user
    RefreshSession.create!(
      user: user,
      refresh_jti: "jti-dup",
      refresh_token_hash: "hash-1",
      expires_at: 1.day.from_now
    )

    duplicate = RefreshSession.new(
      user: user,
      refresh_jti: "jti-dup",
      refresh_token_hash: "hash-2",
      expires_at: 1.day.from_now
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:refresh_jti], "has already been taken"
  end

  test "active state returns true when not revoked and not expired" do
    user = build_user
    refresh_session = RefreshSession.create!(
      user: user,
      refresh_jti: "jti-active",
      refresh_token_hash: "hash-active",
      expires_at: 1.day.from_now
    )

    assert refresh_session.active?
    assert_not refresh_session.revoked?
    assert_not refresh_session.expired?
  end

  test "active state returns false when revoked" do
    user = build_user
    refresh_session = RefreshSession.create!(
      user: user,
      refresh_jti: "jti-revoked",
      refresh_token_hash: "hash-revoked",
      expires_at: 1.day.from_now,
      revoked_at: Time.current
    )

    assert refresh_session.revoked?
    assert_not refresh_session.active?
  end

  test "active state returns false when expired" do
    user = build_user
    refresh_session = RefreshSession.create!(
      user: user,
      refresh_jti: "jti-expired",
      refresh_token_hash: "hash-expired",
      expires_at: 1.minute.ago
    )

    assert refresh_session.expired?
    assert_not refresh_session.active?
  end

  test "schema does not persist plaintext token column" do
    assert_not RefreshSession.column_names.include?("refresh_token")
  end
end
