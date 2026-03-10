require "test_helper"

class UserTest < ActiveSupport::TestCase
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
end
