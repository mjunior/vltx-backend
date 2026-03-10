class Admin::Auth::RefreshesController < Admin::ApplicationController
  def create
    return render_invalid_payload unless request.content_mime_type&.json?
    return render_invalid_payload unless unknown_refresh_keys.empty?
    return render_invalid_payload if refresh_params[:refresh_token].blank?

    result = AdminAuth::Sessions::RotateSession.call(refresh_token: refresh_params[:refresh_token])
    return render_invalid_token unless result.success?

    render json: AdminAuth::TokenPairSerializer.call(
      admin: result.admin,
      access_token: result.access_token,
      refresh_token: result.refresh_token
    ), status: :ok
  end

  private

  def refresh_params
    params.permit(:refresh_token)
  end

  def unknown_refresh_keys
    allowed = %w[controller action format refresh_token refresh]
    params.to_unsafe_h.keys - allowed
  end
end
