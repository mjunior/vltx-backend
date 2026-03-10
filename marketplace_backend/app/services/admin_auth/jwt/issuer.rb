require "securerandom"

module AdminAuth
  module Jwt
    class Issuer
      Token = Struct.new(:token, :jti, :expires_at, :payload, keyword_init: true)

      class << self
        def issue_access(admin_id:, now: Time.current)
          issue(type: "access", admin_id: admin_id, now: now)
        end

        def issue_refresh(admin_id:, now: Time.current)
          issue(type: "refresh", admin_id: admin_id, now: now)
        end

        private

        def issue(type:, admin_id:, now:)
          jti = SecureRandom.uuid
          expires_at = now + ttl_for(type)
          payload = {
            sub: admin_id.to_s,
            jti: jti,
            type: type,
            iat: now.to_i,
            exp: expires_at.to_i,
          }

          token = ::JWT.encode(payload, Config.secret_for(type), Config.algorithm)
          Token.new(token: token, jti: jti, expires_at: expires_at, payload: payload.stringify_keys)
        end

        def ttl_for(type)
          case type
          when "access"
            Config.access_ttl
          when "refresh"
            Config.refresh_ttl
          else
            raise ArgumentError, "Unsupported token type: #{type}"
          end
        end
      end
    end
  end
end
