module AdminUsers
  class Deactivate
    Result = Struct.new(:success?, :user, :error_code, keyword_init: true)

    class << self
      def call(user_id:)
        new(user_id: user_id).call
      end
    end

    def initialize(user_id:)
      @user_id = user_id
    end

    def call
      user = User.find_by(id: @user_id)
      return Result.new(success?: false, error_code: :not_found) unless user

      ActiveRecord::Base.transaction do
        user.update!(active: false) if user.active?
        Auth::Sessions::RevokeAll.call(user: user)
      end

      Result.new(success?: true, user: user)
    rescue StandardError
      Result.new(success?: false, error_code: :invalid_payload)
    end
  end
end
