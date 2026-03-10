module AdminAuth
  module Sessions
    class FindActiveSession
      class << self
        def call(refresh_jti:, refresh_token:)
          session = AdminRefreshSession.find_by(
            refresh_jti: refresh_jti,
            refresh_token_hash: TokenDigest.call(refresh_token)
          )

          return nil unless session
          return nil unless session.active?
          return nil unless session.admin.active?

          session
        end
      end
    end
  end
end
