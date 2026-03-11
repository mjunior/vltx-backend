class Admin::DashboardController < Admin::ApplicationController
  before_action :authenticate_admin!

  def show
    result = AdminDashboard::ReadSummary.call
    return render_invalid_payload unless result.success?

    render json: { data: result.summary }, status: :ok
  end
end
