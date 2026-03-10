class Admin::ApplicationController < ApplicationController
  private

  attr_reader :current_admin

  def authenticate_admin!
    @current_admin = AdminAuth::Jwt::AccessSubject.call(
      authorization_header: request.headers["Authorization"]
    )
    return if @current_admin

    render_invalid_token
  end
end
