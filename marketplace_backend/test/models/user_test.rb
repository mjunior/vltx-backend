require "test_helper"

class UserTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  test "normalizes email before validation" do
    user = User.new(email: "  USER@Example.COM  ", password: "password123", password_confirmation: "password123")

    assert user.valid?
    assert_equal "user@example.com", user.email
  end

  test "enforces case-insensitive email uniqueness" do
    User.create!(email: "owner@example.com", password: "password123", password_confirmation: "password123")

    duplicate = User.new(email: "OWNER@EXAMPLE.COM", password: "password123", password_confirmation: "password123")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been taken"
  end

  test "requires minimum password length" do
    user = User.new(email: "a@b.com", password: "short", password_confirmation: "short")

    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 8 characters)"
  end

  test "has one profile" do
    user = User.create!(email: "one@example.com", password: "password123", password_confirmation: "password123")
    profile = user.create_profile!

    assert_equal profile, user.profile
  end

  test "defaults verification status to unverified" do
    user = User.create!(email: "verification@example.com", password: "password123", password_confirmation: "password123")

    assert_equal "unverified", user.verification_status
    assert user.unverified?
  end

  test "is active by default" do
    user = User.create!(email: "active-default@example.com", password: "password123", password_confirmation: "password123")

    assert user.active?
  end

  test "password reset token resolves within 15 minutes" do
    user = User.create!(email: "reset-token@example.com", password: "password123", password_confirmation: "password123")
    token = user.issue_password_reset_token!

    assert_equal user.id, User.find_by_token_for(:password_reset, token)&.id

    travel 16.minutes do
      assert_nil User.find_by_token_for(:password_reset, token)
    end
  end

  test "issuing a new password reset token invalidates the previous one" do
    user = User.create!(email: "reset-rotate@example.com", password: "password123", password_confirmation: "password123")
    first = user.issue_password_reset_token!
    second = user.issue_password_reset_token!

    assert_nil User.find_by_token_for(:password_reset, first)
    assert_equal user.id, User.find_by_token_for(:password_reset, second)&.id
  end

  test "password reset token becomes invalid after password changes" do
    user = User.create!(email: "reset-password-change@example.com", password: "password123", password_confirmation: "password123")
    token = user.issue_password_reset_token!

    user.update!(password: "newpassword123", password_confirmation: "newpassword123")

    assert_nil User.find_by_token_for(:password_reset, token)
  end
end
