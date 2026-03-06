module Auth
  class SignupsController < ApplicationController
    def create
      result = Users::Create.call(signup_params.to_h.symbolize_keys)

      if result.success?
        render json: {
          data: {
            id: result.user.id,
            email: result.user.email,
            profile_id: result.user.profile.id,
          },
        }, status: :created
      else
        render_invalid_signup
      end
    end

    private

    def signup_params
      params.require(:user).permit(:email, :password, :password_confirmation)
    end
  end
end
