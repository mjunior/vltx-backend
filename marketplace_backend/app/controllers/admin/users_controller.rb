class Admin::UsersController < Admin::ApplicationController
  before_action :authenticate_admin!

  def verification_status
    user = User.find_by(id: params[:id])
    return render_not_found unless user

    render json: {
      data: Admin::Users::VerificationStatusSerializer.call(user: user)
    }, status: :ok
  end

  private

  def render_not_found
    render json: { error: "nao encontrado" }, status: :not_found
  end
end
