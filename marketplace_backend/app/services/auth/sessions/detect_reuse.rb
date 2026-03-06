module Auth
  module Sessions
    class DetectReuse
      Result = Struct.new(:reuse_detected, :user_id, keyword_init: true)

      class << self
        def call(refresh_jti:, user_id: nil, refresh_token: nil)
          session = RefreshSession.find_by(refresh_jti: refresh_jti)
          return handle_missing_session(user_id) unless session

          return trigger_incident(session.user) if session.revoked?

          if refresh_token.present?
            expected_hash = TokenDigest.call(refresh_token)
            return trigger_incident(session.user) if session.refresh_token_hash != expected_hash
          end

          Result.new(reuse_detected: false, user_id: session.user_id)
        end

        private

        def handle_missing_session(user_id)
          user = User.find_by(id: user_id)
          return Result.new(reuse_detected: false, user_id: nil) unless user

          # Signed refresh token with unknown jti indicates probable replay/old token use.
          trigger_incident(user)
        end

        def trigger_incident(user)
          RevokeAll.call(user: user)
          Result.new(reuse_detected: true, user_id: user.id)
        end
      end
    end
  end
end
