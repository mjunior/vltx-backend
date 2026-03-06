module Auth
  module Sessions
    class CreateSession
      class << self
        def call(user:, refresh_token:)
          RefreshSession.create!(
            user: user,
            refresh_jti: refresh_token.jti,
            refresh_token_hash: TokenDigest.call(refresh_token.token),
            expires_at: refresh_token.expires_at
          )
        end
      end
    end
  end
end
