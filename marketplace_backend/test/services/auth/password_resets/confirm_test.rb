require "test_helper"

module Auth
  module PasswordResets
    class ConfirmTest < ActiveSupport::TestCase
      def create_user(email: "reset-service@example.com", password: "password123")
        Users::Create.call(
          email: email,
          password: password,
          password_confirmation: password
        ).user
      end

      test "does not consume token when password update is invalid" do
        user = create_user
        token = user.issue_password_reset_token!

        result = Confirm.call(
          token: token,
          password: "short",
          password_confirmation: "short"
        )

        assert_not result.success?
        assert_equal :invalid_payload, result.error_code
        assert_equal user.id, User.find_by_token_for(:password_reset, token)&.id
      end

      test "token cannot reset another user" do
        user = create_user(email: "owner-reset-service@example.com")
        other_user = create_user(email: "other-reset-service@example.com")
        token = user.issue_password_reset_token!

        Confirm.call(
          token: token,
          password: "newpassword123",
          password_confirmation: "newpassword123"
        )

        assert user.reload.authenticate("newpassword123")
        assert other_user.reload.authenticate("password123")
      end
    end
  end
end
