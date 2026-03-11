module Auth
  module PasswordResets
    class Confirm
      Result = Struct.new(:success?, :error_code, keyword_init: true)

      class << self
        def call(token:, password:, password_confirmation:)
          new(token:, password:, password_confirmation:).call
        end
      end

      def initialize(token:, password:, password_confirmation:)
        @token = token
        @password = password
        @password_confirmation = password_confirmation
      end

      def call
        return Result.new(success?: false, error_code: :invalid_payload) if invalid_payload?

        user = User.find_by_token_for(:password_reset, @token)
        return Result.new(success?: false, error_code: :invalid_token) unless user&.active?

        result = nil

        user.with_lock do
          user.reload

          unless user.active? && token_matches?(user)
            result = Result.new(success?: false, error_code: :invalid_token)
            next
          end

          if user.update(password: @password, password_confirmation: @password_confirmation, password_reset_nonce: SecureRandom.hex(16))
            Auth::Sessions::RevokeAll.call(user: user)
            result = Result.new(success?: true)
          else
            result = Result.new(success?: false, error_code: :invalid_payload)
          end
        end

        result || Result.new(success?: false, error_code: :invalid_token)
      rescue StandardError
        Result.new(success?: false, error_code: :invalid_token)
      end

      private

      def invalid_payload?
        @token.blank? || @password.blank? || @password_confirmation.blank?
      end

      def token_matches?(user)
        User.find_by_token_for(:password_reset, @token)&.id == user.id
      end
    end
  end
end
