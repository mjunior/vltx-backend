class Admin::Auth::LogoutsController < Admin::ApplicationController
  def create
    return render_invalid_payload unless request.content_mime_type&.json?

    admin = AdminAuth::Jwt::AccessSubject.call(authorization_header: request.headers["Authorization"])
    return render_invalid_token unless admin

    AdminAuth::Sessions::RevokeAll.call(admin: admin)
    head :no_content
  end
end
