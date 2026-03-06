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
end
