require "digest"

module AdminAuth
  module Sessions
    class TokenDigest
      class << self
        def call(token)
          raise ArgumentError, "token is required" if token.blank?

          Digest::SHA256.hexdigest("#{token}#{AdminAuth::Jwt::Config.refresh_pepper}")
        end
      end
    end
  end
end
