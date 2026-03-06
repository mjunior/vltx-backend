require "digest"

module Auth
  module Sessions
    class TokenDigest
      class << self
        def call(token)
          raise ArgumentError, "token is required" if token.blank?

          Digest::SHA256.hexdigest("#{token}#{Auth::Jwt::Config.refresh_pepper}")
        end
      end
    end
  end
end
