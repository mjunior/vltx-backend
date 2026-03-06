module Auth
  module Jwt
    class Config
      class ConfigurationError < StandardError; end

      ALGORITHM = "HS256".freeze
      ACCESS_TTL = 15.minutes
      REFRESH_TTL = 7.days

      class << self
        def load_from_env!
          access_secret = ENV["JWT_ACCESS_SECRET"]
          refresh_secret = ENV["JWT_REFRESH_SECRET"]
          refresh_pepper = ENV["JWT_REFRESH_PEPPER"]

          missing_keys = []
          missing_keys << "JWT_ACCESS_SECRET" if access_secret.blank?
          missing_keys << "JWT_REFRESH_SECRET" if refresh_secret.blank?
          missing_keys << "JWT_REFRESH_PEPPER" if refresh_pepper.blank?

          if missing_keys.any?
            raise ConfigurationError, "Missing JWT configuration: #{missing_keys.join(', ')}"
          end

          if access_secret == refresh_secret
            raise ConfigurationError, "JWT_ACCESS_SECRET and JWT_REFRESH_SECRET must differ"
          end

          if [access_secret, refresh_secret].include?(refresh_pepper)
            raise ConfigurationError, "JWT_REFRESH_PEPPER must differ from JWT secrets"
          end

          @config = {
            access_secret: access_secret,
            refresh_secret: refresh_secret,
            refresh_pepper: refresh_pepper,
          }.freeze
        end

        def algorithm
          ALGORITHM
        end

        def access_ttl
          ACCESS_TTL
        end

        def refresh_ttl
          REFRESH_TTL
        end

        def access_secret
          fetch!(:access_secret)
        end

        def refresh_secret
          fetch!(:refresh_secret)
        end

        def refresh_pepper
          fetch!(:refresh_pepper)
        end

        def secret_for(type)
          case type.to_s
          when "access"
            access_secret
          when "refresh"
            refresh_secret
          else
            raise ArgumentError, "Unsupported token type: #{type}"
          end
        end

        private

        def fetch!(key)
          return @config.fetch(key) if @config

          load_from_env!
          @config.fetch(key)
        end
      end
    end
  end
end
