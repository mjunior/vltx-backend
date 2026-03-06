module Auth
  module Sessions
    class RotateSession
      Result = Struct.new(:success?, :user, :access_token, :refresh_token, keyword_init: true)

      class << self
        def call(refresh_token:)
          decoded = Auth::Jwt::Verifier.verify!(token: refresh_token, expected_type: "refresh")
          refresh_jti = decoded.payload.fetch("jti")
          user_id = decoded.payload.fetch("sub")

          reuse_result = DetectReuse.call(
            refresh_jti: refresh_jti,
            user_id: user_id,
            refresh_token: refresh_token
          )
          return Result.new(success?: false) if reuse_result.reuse_detected

          session = FindActiveSession.call(refresh_jti: refresh_jti, refresh_token: refresh_token)
          return Result.new(success?: false) unless session

          session.with_lock do
            session.reload
            return Result.new(success?: false) unless active_session?(session, refresh_jti, refresh_token)

            access = Auth::Jwt::Issuer.issue_access(user_id: session.user_id)
            new_refresh = Auth::Jwt::Issuer.issue_refresh(user_id: session.user_id)
            now = Time.current

            session.update!(
              refresh_jti: new_refresh.jti,
              refresh_token_hash: TokenDigest.call(new_refresh.token),
              expires_at: new_refresh.expires_at,
              rotated_at: now
            )

            Result.new(success?: true, user: session.user, access_token: access, refresh_token: new_refresh)
          end
        rescue Auth::Jwt::Errors::InvalidToken
          Result.new(success?: false)
        end

        private

        def active_session?(session, refresh_jti, refresh_token)
          expected_hash = TokenDigest.call(refresh_token)

          session.refresh_jti == refresh_jti &&
            session.refresh_token_hash == expected_hash &&
            session.active?
        end
      end
    end
  end
end
