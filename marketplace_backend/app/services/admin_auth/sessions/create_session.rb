module AdminAuth
  module Sessions
    class CreateSession
      class << self
        def call(admin:, refresh_token:)
          AdminRefreshSession.create!(
            admin: admin,
            refresh_jti: refresh_token.jti,
            refresh_token_hash: TokenDigest.call(refresh_token.token),
            expires_at: refresh_token.expires_at
          )
        end
      end
    end
  end
end
