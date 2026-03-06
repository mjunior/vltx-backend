module Auth
  class LoginsController < ApplicationController
    def create
      return render_invalid_payload if login_params[:email].blank? || login_params[:password].blank?

      user = User.find_by(email: login_params[:email].to_s.downcase.strip)

      unless user&.authenticate(login_params[:password])
        return render_invalid_credentials
      end

      access_token = Auth::Jwt::Issuer.issue_access(user_id: user.id)
      refresh_token = Auth::Jwt::Issuer.issue_refresh(user_id: user.id)
      Auth::Sessions::CreateSession.call(user: user, refresh_token: refresh_token)

      render json: Auth::TokenPairSerializer.call(
        user: user,
        access_token: access_token,
        refresh_token: refresh_token
      ), status: :ok
    end

    private

    def login_params
      params.permit(:email, :password)
    end
  end
end
