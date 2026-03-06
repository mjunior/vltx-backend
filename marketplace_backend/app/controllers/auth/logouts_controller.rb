module Auth
  class LogoutsController < ApplicationController
    def create
      return render_invalid_payload unless request.content_mime_type&.json?

      user = Auth::Jwt::AccessSubject.call(authorization_header: request.headers["Authorization"])
      return render_invalid_token unless user

      Auth::Sessions::RevokeAll.call(user: user)
      head :no_content
    end
  end
end
