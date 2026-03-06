class ApplicationController < ActionController::API
  private

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
end
