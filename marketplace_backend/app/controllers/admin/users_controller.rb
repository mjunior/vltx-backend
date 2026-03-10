class Admin::UsersController < Admin::ApplicationController
  before_action :authenticate_admin!

  def verification_status
    user = User.find_by(id: params[:id])
    return render_not_found unless user

    render json: {
      data: Admin::Users::VerificationStatusSerializer.call(user: user)
    }, status: :ok
  end

  def deactivate
    result = AdminUsers::Deactivate.call(user_id: params[:id])
    return render_not_found if result.error_code == :not_found
    return render_invalid_payload unless result.success?

    render json: {
      data: {
        id: result.user.id,
        active: result.user.active,
      }
    }, status: :ok
  end

  private

  def render_not_found
    render json: { error: "nao encontrado" }, status: :not_found
  end
end
