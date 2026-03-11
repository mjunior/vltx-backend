class ProfilesController < ApplicationController
  wrap_parameters false

  before_action :authenticate_user!

  def update
    return render_invalid_payload unless request.content_mime_type&.json?
    return render_invalid_payload unless unknown_profile_keys.empty?

    result = Profiles::UpdateProfile.call(user: current_user, params: profile_params.to_h)
    return render_invalid_payload unless result.success?

    render json: Profiles::ProfileSerializer.call(profile: result.profile), status: :ok
  end

  def upload_photo
    return render_invalid_payload unless unknown_photo_upload_keys.empty?

    result = Profiles::UploadPhoto.call(user: current_user, photo: photo_upload_param)
    return render_upload_photo_error(result.error_code) unless result.success?

    render json: Profiles::ProfileSerializer.call(profile: result.profile), status: :ok
  end

  private

  def profile_params
    ActionController::Parameters.new(raw_payload).permit(:name, :address)
  end

  def raw_payload
    payload = request.request_parameters
    return {} unless payload.is_a?(Hash)

    payload
  end

  def unknown_profile_keys
    raw_payload.keys.map(&:to_s) - %w[name address]
  end

  def photo_upload_param
    params[:photo]
  end

  def unknown_photo_upload_keys
    params.keys.map(&:to_s) - %w[controller action photo]
  end

  def render_upload_photo_error(error_code)
    case error_code
    when :missing_photo
      render_error("foto obrigatoria", status: :unprocessable_entity, code: error_code)
    when :invalid_photo_type
      render_error("tipo de foto invalido", status: :unprocessable_entity, code: error_code)
    when :empty_photo
      render_error("foto vazia", status: :unprocessable_entity, code: error_code)
    when :photo_too_large
      render_error("foto excede o limite de 5MB", status: :unprocessable_entity, code: error_code)
    when :invalid_configuration
      render_error("upload indisponivel", status: :internal_server_error, code: error_code)
    when :upload_failed
      render_error("falha ao enviar foto", status: :bad_gateway, code: error_code)
    when :profile_not_found
      render_error("nao encontrado", status: :not_found, code: error_code)
    else
      render_invalid_payload
    end
  end
end
