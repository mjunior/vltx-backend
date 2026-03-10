module Users
  class Create
    Result = Struct.new(:success?, :user, :error_code, keyword_init: true)

    def self.call(params)
      new(params).call
    end

    def initialize(params)
      @params = params || {}
    end

    def call
      return Result.new(success?: false, error_code: :invalid_signup) unless valid_signup_payload?

      user = nil

      ActiveRecord::Base.transaction do
        user = User.new(user_attributes)
        raise ActiveRecord::Rollback unless user.save

        profile = user.build_profile(full_name: nil, photo_url: nil)
        raise ActiveRecord::Rollback unless profile.save
      end

      if user&.persisted? && user.profile&.persisted?
        return Result.new(success?: true, user: user)
      end

      Result.new(success?: false, error_code: :invalid_signup)
    rescue StandardError
      Result.new(success?: false, error_code: :invalid_signup)
    end

    private

    def valid_signup_payload?
      @params[:email].present? &&
        @params[:password].present? &&
        @params[:password_confirmation].present?
    end

    def user_attributes
      {
        email: @params[:email],
        password: @params[:password],
        password_confirmation: @params[:password_confirmation],
        active: true,
      }
    end
  end
end
