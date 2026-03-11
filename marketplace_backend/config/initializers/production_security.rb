require "uri"

unless defined?(ProductionSecurity)
  module ProductionSecurity
    class ConfigurationError < StandardError; end

    HEALTHCHECK_PATH = "/up".freeze
    DEFAULT_LOCAL_CORS_ORIGINS = ["http://localhost:4200"].freeze

    class << self
      def configure!(config, env: ENV, rails_env: Rails.env)
        return unless production_env?(rails_env)

        config.assume_ssl = assume_ssl?(env: env, rails_env: rails_env)
        config.force_ssl = force_ssl?(env: env, rails_env: rails_env)
        config.ssl_options = { redirect: { exclude: healthcheck_exclusion } }
        config.hosts = allowed_hosts(env: env, rails_env: rails_env)
        config.host_authorization = { exclude: healthcheck_exclusion }
      end

      def assume_ssl?(env: ENV, rails_env: Rails.env)
        return false unless production_env?(rails_env)

        boolean_env(env.fetch("ASSUME_SSL", env.fetch("FORCE_SSL", "true")))
      end

      def force_ssl?(env: ENV, rails_env: Rails.env)
        return false unless production_env?(rails_env)

        boolean_env(env.fetch("FORCE_SSL", "true"))
      end

      def allowed_hosts(env: ENV, rails_env: Rails.env)
        hosts = parse_csv(env["APP_HOSTS"])
        hosts.concat(parse_csv(env["RAILWAY_PUBLIC_DOMAIN"]).map { |value| normalize_host(value) })
        hosts = hosts.reject(&:blank?).uniq

        return hosts unless production_env?(rails_env)

        raise ConfigurationError, "APP_HOSTS or RAILWAY_PUBLIC_DOMAIN must be set in production" if hosts.empty?

        hosts
      end

      def cors_allowed_origins(env: ENV, rails_env: Rails.env)
        origins = parse_csv(env["CORS_ALLOWED_ORIGINS"])
        return origins.presence || DEFAULT_LOCAL_CORS_ORIGINS unless production_env?(rails_env)

        raise ConfigurationError, "CORS_ALLOWED_ORIGINS must be set in production" if origins.empty?

        origins
      end

      def cors_origin_allowed?(origin, env: ENV, rails_env: Rails.env)
        return false if origin.blank?

        cors_allowed_origins(env: env, rails_env: rails_env).include?(origin)
      end

      def healthcheck_exclusion
        ->(request) { request.path == HEALTHCHECK_PATH }
      end

      private

      def production_env?(rails_env)
        rails_env.to_s == "production"
      end

      def parse_csv(value)
        value.to_s.split(",").map(&:strip).reject(&:blank?)
      end

      def normalize_host(value)
        uri = URI.parse(value)
        uri.host.presence || value
      rescue URI::InvalidURIError
        value
      end

      def boolean_env(value)
        ActiveModel::Type::Boolean.new.cast(value)
      end
    end
  end
end
