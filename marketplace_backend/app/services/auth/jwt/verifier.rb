module Auth
  module Jwt
    class Verifier
      DecodedToken = Struct.new(:payload, keyword_init: true)

      class << self
        def verify!(token:, expected_type:)
          payload = decode(token: token, type: expected_type)
          validate_payload!(payload, expected_type)
          DecodedToken.new(payload: payload)
        rescue ::JWT::DecodeError, ::JWT::ExpiredSignature, ArgumentError
          raise Errors::InvalidToken, "token invalido"
        end

        private

        def decode(token:, type:)
          payload, = ::JWT.decode(
            token,
            Config.secret_for(type),
            true,
            algorithm: Config.algorithm,
            verify_expiration: true
          )

          payload
        end

        def validate_payload!(payload, expected_type)
          raise ArgumentError, "Missing jti" if payload["jti"].blank?
          raise ArgumentError, "Invalid token type" if payload["type"] != expected_type.to_s
        end
      end
    end
  end
end
