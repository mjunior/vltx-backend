module Auth
  module Sessions
    class FindActiveSession
      class << self
        def call(refresh_jti:, refresh_token:)
          session = RefreshSession.find_by(
            refresh_jti: refresh_jti,
            refresh_token_hash: TokenDigest.call(refresh_token)
          )

          return nil unless session
          return nil unless session.active?
          return nil unless session.user.active?

          session
        end
      end
    end
  end
end
