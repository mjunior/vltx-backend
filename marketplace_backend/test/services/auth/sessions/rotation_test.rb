require "test_helper"

module Auth
  module Sessions
    class RotationTest < ActiveSupport::TestCase
      def create_user(email: "rotation@example.com")
        Users::Create.call(
          email: email,
          password: "password123",
          password_confirmation: "password123"
        ).user
      end

      test "rotate session succeeds once and then rejects previous refresh token" do
        user = create_user
        refresh = Auth::Jwt::Issuer.issue_refresh(user_id: user.id)
        CreateSession.call(user: user, refresh_token: refresh)

        first = RotateSession.call(refresh_token: refresh.token)
        assert first.success?

        second = RotateSession.call(refresh_token: refresh.token)
        assert_not second.success?
      end

      test "rotate session returns failure for malformed token" do
        result = RotateSession.call(refresh_token: "not-a-token")

        assert_not result.success?
      end

      test "rotate session updates same session record" do
        user = create_user
        refresh = Auth::Jwt::Issuer.issue_refresh(user_id: user.id)
        session = CreateSession.call(user: user, refresh_token: refresh)

        result = RotateSession.call(refresh_token: refresh.token)
        assert result.success?

        session.reload
        assert_not_equal refresh.jti, session.refresh_jti
        assert session.rotated_at.present?
      end
    end
  end
end
