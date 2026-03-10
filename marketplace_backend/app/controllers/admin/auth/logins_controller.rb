class Admin::Auth::LoginsController < Admin::ApplicationController
  def create
    return render_invalid_payload if login_params[:email].blank? || login_params[:password].blank?

    admin = Admin.find_by(email: login_params[:email].to_s.downcase.strip)
    return render_invalid_credentials unless admin&.active? && admin.authenticate(login_params[:password])

    access_token = AdminAuth::Jwt::Issuer.issue_access(admin_id: admin.id)
    refresh_token = AdminAuth::Jwt::Issuer.issue_refresh(admin_id: admin.id)
    AdminAuth::Sessions::CreateSession.call(admin: admin, refresh_token: refresh_token)

    render json: AdminAuth::TokenPairSerializer.call(
      admin: admin,
      access_token: access_token,
      refresh_token: refresh_token
    ), status: :ok
  end

  private

  def login_params
    params.permit(:email, :password)
  end
end
