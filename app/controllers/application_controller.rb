class ApplicationController < ActionController::API
  private

  def render_invalid_signup
    render json: { error: "cadastro invalido" }, status: :unprocessable_entity
  end
end
