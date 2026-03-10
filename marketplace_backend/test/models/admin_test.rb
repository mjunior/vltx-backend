require "test_helper"

class AdminTest < ActiveSupport::TestCase
  test "normalizes email before validation" do
    admin = Admin.new(email: "  ADMIN@Example.COM  ", password: "password123", password_confirmation: "password123")

    assert admin.valid?
    assert_equal "admin@example.com", admin.email
  end

  test "enforces case-insensitive email uniqueness" do
    Admin.create!(email: "admin@example.com", password: "password123", password_confirmation: "password123")

    duplicate = Admin.new(email: "ADMIN@example.com", password: "password123", password_confirmation: "password123")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been taken"
  end

  test "requires minimum password length" do
    admin = Admin.new(email: "a@b.com", password: "short", password_confirmation: "short")

    assert_not admin.valid?
    assert_includes admin.errors[:password], "is too short (minimum is 8 characters)"
  end

  test "is active by default" do
    admin = Admin.create!(email: "active-admin@example.com", password: "password123", password_confirmation: "password123")

    assert admin.active?
  end
end
