module Profiles
  class UpdateProfile
    Result = Struct.new(:success?, :profile, keyword_init: true)

    ALLOWED_KEYS = %i[name address].freeze

    class << self
      def call(user:, params:)
        new(user: user, params: params).call
      end
    end

    def initialize(user:, params:)
      @user = user
      @params = params || {}
    end

    def call
      return Result.new(success?: false) unless @user&.profile

      normalized = @params.to_h.deep_symbolize_keys
      return Result.new(success?: false) if normalized.empty?
      return Result.new(success?: false) unless (normalized.keys - ALLOWED_KEYS).empty?
      return Result.new(success?: false) unless allowed_value_types?(normalized)

      update_attrs = {}
      update_attrs[:full_name] = normalize_text(normalized[:name]) if normalized.key?(:name)
      update_attrs[:address] = normalize_text(normalized[:address]) if normalized.key?(:address)

      return Result.new(success?: false) if update_attrs.empty?

      return Result.new(success?: false) unless @user.profile.update(update_attrs)

      Result.new(success?: true, profile: @user.profile)
    rescue StandardError
      Result.new(success?: false)
    end

    private

    def normalize_text(value)
      return nil if value.nil?

      value.to_s.strip
    end

    def allowed_value_types?(normalized)
      normalized.values.all? { |value| value.nil? || value.is_a?(String) }
    end
  end
end
