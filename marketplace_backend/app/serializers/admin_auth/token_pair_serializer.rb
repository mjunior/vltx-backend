module AdminAuth
  class TokenPairSerializer
    class << self
      def call(admin:, access_token:, refresh_token:)
        {
          data: {
            id: admin.id,
            email: admin.email,
            access_token: access_token.token,
            refresh_token: refresh_token.token,
            token_type: "Bearer",
            access_expires_in: AdminAuth::Jwt::Config.access_ttl.to_i,
            refresh_expires_in: AdminAuth::Jwt::Config.refresh_ttl.to_i,
          },
        }
      end
    end
  end
end
