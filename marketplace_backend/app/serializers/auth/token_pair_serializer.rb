module Auth
  class TokenPairSerializer
    class << self
      def call(user:, access_token:, refresh_token:)
        {
          data: {
            id: user.id,
            email: user.email,
            profile_id: user.profile.id,
            access_token: access_token.token,
            refresh_token: refresh_token.token,
            token_type: "Bearer",
            access_expires_in: Auth::Jwt::Config.access_ttl.to_i,
            refresh_expires_in: Auth::Jwt::Config.refresh_ttl.to_i,
          },
        }
      end
    end
  end
end
