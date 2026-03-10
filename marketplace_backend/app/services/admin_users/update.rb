module AdminUsers
  class Update
    Result = Struct.new(:success?, :user, :error_code, keyword_init: true)

    ALLOWED_KEYS = %i[email active verification_status name address photo_url].freeze
    PROFILE_KEYS = %i[name address photo_url].freeze

    class << self
      def call(user_id:, params:)
        new(user_id: user_id, params: params).call
      end
    end

    def initialize(user_id:, params:)
      @user_id = user_id
      @params = params || {}
    end

    def call
      user = User.includes(:profile, :wallet).find_by(id: @user_id)
      return Result.new(success?: false, error_code: :not_found) unless user

      normalized = normalize_params
      return Result.new(success?: false, error_code: :invalid_payload) if normalized.empty?
      return Result.new(success?: false, error_code: :invalid_payload) unless valid_keys?(normalized)
      return Result.new(success?: false, error_code: :invalid_payload) unless valid_value_types?(normalized)

      return reactivate_inactive_user(user:, normalized:) unless user.active?

      return deactivate_active_user(user:, normalized:) if deactivate_request?(normalized)

      user_attrs = build_user_attrs(normalized)
      profile_attrs = build_profile_attrs(normalized)
      return Result.new(success?: false, error_code: :invalid_payload) if user_attrs.empty? && profile_attrs.empty?

      ActiveRecord::Base.transaction do
        user.update!(user_attrs) if user_attrs.any?
        user.profile.update!(profile_attrs) if profile_attrs.any?
      end

      Result.new(success?: true, user: user.reload)
    rescue StandardError
      Result.new(success?: false, error_code: :invalid_payload)
    end

    private

    def normalize_params
      @params.to_h.deep_symbolize_keys
    end

    def valid_keys?(normalized)
      (normalized.keys - ALLOWED_KEYS).empty?
    end

    def valid_value_types?(normalized)
      normalized.all? do |key, value|
        case key
        when :active
          [true, false].include?(value)
        when :verification_status
          value.is_a?(String)
        when :email
          value.is_a?(String)
        when :name, :address, :photo_url
          value.nil? || value.is_a?(String)
        else
          false
        end
      end
    end

    def reactivate_inactive_user(user:, normalized:)
      return Result.new(success?: false, error_code: :invalid_payload) unless normalized == { active: true }

      user.update!(active: true)
      Result.new(success?: true, user: user.reload)
    end

    def deactivate_active_user(user:, normalized:)
      return Result.new(success?: false, error_code: :invalid_payload) unless normalized == { active: false }

      result = AdminUsers::Deactivate.call(user_id: user.id)
      Result.new(success?: result.success?, user: result.user&.reload, error_code: result.error_code)
    end

    def build_user_attrs(normalized)
      attrs = {}
      attrs[:email] = normalized[:email]&.strip if normalized.key?(:email)
      attrs[:verification_status] = normalized[:verification_status]&.strip if normalized.key?(:verification_status)
      if normalized.key?(:active) && normalized[:active] == true
        attrs[:active] = true
      end
      attrs
    end

    def build_profile_attrs(normalized)
      attrs = {}
      attrs[:full_name] = normalize_text(normalized[:name]) if normalized.key?(:name)
      attrs[:address] = normalize_text(normalized[:address]) if normalized.key?(:address)
      attrs[:photo_url] = normalize_text(normalized[:photo_url]) if normalized.key?(:photo_url)
      attrs
    end

    def normalize_text(value)
      return nil if value.nil?

      value.to_s.strip
    end

    def deactivate_request?(normalized)
      normalized.key?(:active) && normalized[:active] == false
    end
  end
end
