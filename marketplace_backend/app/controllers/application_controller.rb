class ApplicationController < ActionController::API
  private
  attr_reader :current_user

  def authenticate_user!
    @current_user = Auth::Jwt::AccessSubject.call(
      authorization_header: request.headers["Authorization"]
    )
    return if @current_user

    render_invalid_token
  end

  def render_invalid_signup
    render json: { error: "cadastro invalido" }, status: :unprocessable_entity
  end

  def render_invalid_credentials
    render json: { error: "credenciais invalidas" }, status: :unauthorized
  end

  def render_invalid_token
    render json: { error: "token invalido" }, status: :unauthorized
  end

  def render_invalid_payload
    render json: { error: "payload invalido" }, status: :unprocessable_entity
  end

  def render_error(message, status:, code: nil)
    payload = { error: message }
    payload[:code] = code.to_s if code

    render json: payload, status: status
  end
end
