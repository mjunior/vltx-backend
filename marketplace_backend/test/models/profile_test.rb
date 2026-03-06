require "test_helper"

class ProfileTest < ActiveSupport::TestCase
  test "belongs to user" do
    user = User.create!(email: "profile@example.com", password: "password123", password_confirmation: "password123")
    profile = Profile.new(user: user)

    assert profile.valid?
    assert_equal user, profile.user
  end

  test "supports optional personal fields" do
    user = User.create!(email: "optional@example.com", password: "password123", password_confirmation: "password123")

    profile = Profile.new(user: user, full_name: nil, photo_url: nil)

    assert profile.valid?
  end
end
