require "cgi"

module Auth
  module PasswordResets
    class Request
      Result = Struct.new(:success?, :error_code, keyword_init: true)

      class << self
        def call(email:)
          new(email:).call
        end
      end

      def initialize(email:)
        @raw_email = email
      end

      def call
        return Result.new(success?: false, error_code: :invalid_payload) if normalized_email.blank?

        user = User.active_only.find_by(email: normalized_email)
        return Result.new(success?: true) unless user

        token = user.issue_password_reset_token!
        delivery = EmailService.password_reset(to: user.email, reset_link: reset_link_for(token))

        log_delivery_failure(user.email, delivery.error_code) unless delivery.success?

        Result.new(success?: true)
      rescue StandardError => error
        log_exception(error)
        Result.new(success?: true)
      end

      private

      def normalized_email
        @normalized_email ||= @raw_email.to_s.strip.downcase
      end

      def reset_link_for(token)
        return invalid_configuration! if frontend_reset_password_url.blank?

        separator = frontend_reset_password_url.include?("?") ? "&" : "?"
        "#{frontend_reset_password_url}#{separator}token=#{CGI.escape(token)}"
      end

      def frontend_reset_password_url
        ENV["FRONTEND_RESET_PASSWORD_URL"].to_s.strip
      end

      def invalid_configuration!
        raise ArgumentError, "missing FRONTEND_RESET_PASSWORD_URL"
      end

      def log_delivery_failure(email, error_code)
        Rails.logger.warn(
          {
            event: "auth.password_reset.email_delivery_failed",
            email: email,
            error_code: error_code
          }.to_json
        )
      rescue StandardError
        nil
      end

      def log_exception(error)
        Rails.logger.warn(
          {
            event: "auth.password_reset.request_failed",
            error_class: error.class.name,
            message: error.message
          }.to_json
        )
      rescue StandardError
        nil
      end
    end
  end
end
