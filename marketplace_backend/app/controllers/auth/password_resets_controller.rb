module Auth
  class PasswordResetsController < ApplicationController
    GENERIC_RESPONSE = {
      message: "se o e-mail existir, enviaremos instrucoes para redefinir a senha"
    }.freeze

    def create
      return render_invalid_payload unless request.content_mime_type&.json?
      return render_invalid_payload unless unknown_request_keys.empty?
      return render_invalid_payload if request_params[:email].blank?

      Auth::PasswordResets::Request.call(email: request_params[:email])

      render json: GENERIC_RESPONSE, status: :accepted
    end

    def confirm
      return render_invalid_payload unless request.content_mime_type&.json?
      return render_invalid_payload unless unknown_confirm_keys.empty?

      result = Auth::PasswordResets::Confirm.call(
        token: confirm_params[:token],
        password: confirm_params[:password],
        password_confirmation: confirm_params[:password_confirmation]
      )

      return head :no_content if result.success?
      return render_invalid_payload if result.error_code == :invalid_payload

      render_invalid_token
    end

    private

    def request_params
      params.permit(:email)
    end

    def confirm_params
      params.permit(:token, :password, :password_confirmation)
    end

    def unknown_request_keys
      allowed = %w[controller action format email password_reset]
      params.to_unsafe_h.keys - allowed
    end

    def unknown_confirm_keys
      allowed = %w[controller action format token password password_confirmation password_reset]
      params.to_unsafe_h.keys - allowed
    end
  end
end
