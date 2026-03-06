require "test_helper"

module Auth
  module Jwt
    class VerifierTest < ActiveSupport::TestCase
      test "verifies valid access token" do
        token = Issuer.issue_access(user_id: 10).token

        decoded = Verifier.verify!(token: token, expected_type: "access")

        assert_equal "10", decoded.payload["sub"]
        assert_equal "access", decoded.payload["type"]
        assert decoded.payload["jti"].present?
      end

      test "rejects token with mismatched type" do
        token = Issuer.issue_refresh(user_id: 10).token

        assert_raises(Errors::InvalidToken) do
          Verifier.verify!(token: token, expected_type: "access")
        end
      end

      test "rejects token without jti" do
        payload = {
          sub: "10",
          type: "access",
          iat: Time.current.to_i,
          exp: 15.minutes.from_now.to_i,
        }

        token = ::JWT.encode(payload, Config.access_secret, Config.algorithm)

        assert_raises(Errors::InvalidToken) do
          Verifier.verify!(token: token, expected_type: "access")
        end
      end

      test "rejects malformed token" do
        assert_raises(Errors::InvalidToken) do
          Verifier.verify!(token: "not-a-token", expected_type: "access")
        end
      end
    end
  end
end
