module Auth
  module Jwt
    class AccessSubject
      class << self
        def call(authorization_header:)
          token = bearer_token_from(authorization_header)
          return nil if token.blank?

          decoded = Verifier.verify!(token: token, expected_type: "access")
          user_id = decoded.payload["sub"]
          return nil if user_id.blank?

          User.find_by(id: user_id)
        rescue Errors::InvalidToken
          nil
        end

        private

        def bearer_token_from(header)
          return nil if header.blank?

          scheme, token = header.to_s.split(" ", 2)
          return nil unless scheme == "Bearer"

          token
        end
      end
    end
  end
end
