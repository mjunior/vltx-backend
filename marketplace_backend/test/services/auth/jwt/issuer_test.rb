require "test_helper"

module Auth
  module Jwt
    class IssuerTest < ActiveSupport::TestCase
      test "issues access token with required claims" do
        frozen_time = Time.zone.parse("2026-03-06 10:00:00")

        result = Issuer.issue_access(user_id: 123, now: frozen_time)
        payload, = ::JWT.decode(result.token, Config.access_secret, true, algorithm: Config.algorithm)

        assert_equal "123", payload["sub"]
        assert_equal "access", payload["type"]
        assert_equal frozen_time.to_i, payload["iat"]
        assert_equal (frozen_time + Config.access_ttl).to_i, payload["exp"]
        assert_equal result.jti, payload["jti"]
      end

      test "issues refresh token with required claims" do
        frozen_time = Time.zone.parse("2026-03-06 10:00:00")

        result = Issuer.issue_refresh(user_id: 456, now: frozen_time)
        payload, = ::JWT.decode(result.token, Config.refresh_secret, true, algorithm: Config.algorithm)

        assert_equal "456", payload["sub"]
        assert_equal "refresh", payload["type"]
        assert_equal frozen_time.to_i, payload["iat"]
        assert_equal (frozen_time + Config.refresh_ttl).to_i, payload["exp"]
        assert_equal result.jti, payload["jti"]
      end

      test "access token cannot be decoded with refresh secret" do
        token = Issuer.issue_access(user_id: 789).token

        assert_raises(::JWT::VerificationError) do
          ::JWT.decode(token, Config.refresh_secret, true, algorithm: Config.algorithm)
        end
      end
    end
  end
end
