module Auth
  class SignupsController < ApplicationController
    def create
      result = Users::Create.call(signup_params.to_h.symbolize_keys)

      if result.success?
        access_token = Auth::Jwt::Issuer.issue_access(user_id: result.user.id)
        refresh_token = Auth::Jwt::Issuer.issue_refresh(user_id: result.user.id)
        Auth::Sessions::CreateSession.call(user: result.user, refresh_token: refresh_token)

        render json: Auth::TokenPairSerializer.call(
          user: result.user,
          access_token: access_token,
          refresh_token: refresh_token
        ), status: :created
      else
        render_invalid_signup
      end
    rescue ActionController::ParameterMissing
      render_invalid_signup
    end

    private

    def signup_params
      params.require(:user).permit(:email, :password, :password_confirmation)
    end
  end
end
