require "test_helper"

module Users
  class CreateTest < ActiveSupport::TestCase
    test "creates user and profile when payload is valid" do
      result = Create.call(
        email: "new.user@example.com",
        password: "password123",
        password_confirmation: "password123"
      )

      assert result.success?
      assert_not_nil result.user
      assert result.user.persisted?
      assert result.user.profile.persisted?
      assert_nil result.user.profile.full_name
      assert_nil result.user.profile.photo_url
    end

    test "fails when password confirmation is missing" do
      result = Create.call(email: "a@example.com", password: "password123")

      assert_not result.success?
      assert_equal :invalid_signup, result.error_code
      assert_equal 0, User.count
      assert_equal 0, Profile.count
    end

    test "fails when password is too short" do
      result = Create.call(
        email: "short@example.com",
        password: "short",
        password_confirmation: "short"
      )

      assert_not result.success?
      assert_equal :invalid_signup, result.error_code
      assert_equal 0, User.count
      assert_equal 0, Profile.count
    end

    test "does not create duplicate emails with different case" do
      User.create!(
        email: "owner@example.com",
        password: "password123",
        password_confirmation: "password123"
      )

      result = Create.call(
        email: "OWNER@EXAMPLE.COM",
        password: "password123",
        password_confirmation: "password123"
      )

      assert_not result.success?
      assert_equal :invalid_signup, result.error_code
      assert_equal 1, User.count
      assert_equal 0, Profile.count
    end
  end
end
