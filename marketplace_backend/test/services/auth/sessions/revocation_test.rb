require "test_helper"

module Auth
  module Sessions
    class RevocationTest < ActiveSupport::TestCase
      def create_user(email: "sessions@example.com")
        User.create!(
          email: email,
          password: "password123",
          password_confirmation: "password123"
        )
      end

      def create_refresh_session(user:, refresh_jti:, token:, expires_at: 1.day.from_now, revoked_at: nil)
        RefreshSession.create!(
          user: user,
          refresh_jti: refresh_jti,
          refresh_token_hash: TokenDigest.call(token),
          expires_at: expires_at,
          revoked_at: revoked_at
        )
      end

      test "token digest is deterministic" do
        first = TokenDigest.call("token-abc")
        second = TokenDigest.call("token-abc")

        assert_equal first, second
      end

      test "find active session returns session when jti and hash match" do
        user = create_user
        token = "refresh-token-active"
        session = create_refresh_session(user: user, refresh_jti: "jti-active", token: token)

        found = FindActiveSession.call(refresh_jti: "jti-active", refresh_token: token)

        assert_equal session.id, found.id
      end

      test "find active session returns nil for revoked session" do
        user = create_user
        token = "refresh-token-revoked"
        create_refresh_session(
          user: user,
          refresh_jti: "jti-revoked",
          token: token,
          revoked_at: Time.current
        )

        found = FindActiveSession.call(refresh_jti: "jti-revoked", refresh_token: token)

        assert_nil found
      end

      test "find active session returns nil for expired session" do
        user = create_user
        token = "refresh-token-expired"
        create_refresh_session(
          user: user,
          refresh_jti: "jti-expired",
          token: token,
          expires_at: 1.minute.ago
        )

        found = FindActiveSession.call(refresh_jti: "jti-expired", refresh_token: token)

        assert_nil found
      end

      test "revoke all revokes every active session for user" do
        user = create_user
        other_user = create_user(email: "other-sessions@example.com")

        create_refresh_session(user: user, refresh_jti: "jti-1", token: "token-1")
        create_refresh_session(user: user, refresh_jti: "jti-2", token: "token-2")
        create_refresh_session(user: other_user, refresh_jti: "jti-3", token: "token-3")

        updated_count = RevokeAll.call(user: user)

        assert_equal 2, updated_count
        assert_equal 2, user.refresh_sessions.where.not(revoked_at: nil).count
        assert_equal 0, other_user.refresh_sessions.where.not(revoked_at: nil).count
      end

      test "detect reuse triggers global revoke when revoked token is used" do
        user = create_user
        create_refresh_session(user: user, refresh_jti: "jti-old", token: "token-old", revoked_at: Time.current)
        create_refresh_session(user: user, refresh_jti: "jti-active", token: "token-active")

        result = DetectReuse.call(refresh_jti: "jti-old")

        assert result.reuse_detected
        assert_equal user.id, result.user_id
        assert_equal 2, user.refresh_sessions.where.not(revoked_at: nil).count
      end

      test "detect reuse returns false for active token" do
        user = create_user
        create_refresh_session(user: user, refresh_jti: "jti-ok", token: "token-ok")

        result = DetectReuse.call(refresh_jti: "jti-ok")

        assert_not result.reuse_detected
        assert_equal user.id, result.user_id
      end

      test "detect reuse triggers incident when signed token jti is missing from sessions" do
        user = create_user
        create_refresh_session(user: user, refresh_jti: "jti-active", token: "token-active")

        result = DetectReuse.call(refresh_jti: "jti-missing", user_id: user.id)

        assert result.reuse_detected
        assert_equal user.id, result.user_id
        assert_equal 1, user.refresh_sessions.where.not(revoked_at: nil).count
      end
    end
  end
end
