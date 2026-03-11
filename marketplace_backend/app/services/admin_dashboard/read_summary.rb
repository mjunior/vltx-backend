module AdminDashboard
  class ReadSummary
    Result = Struct.new(:success?, :summary, :error_code, keyword_init: true)

    WINDOW_DAYS = 30

    class << self
      def call(now: Time.current)
        new(now: now).call
      end
    end

    def initialize(now:)
      @now = now
    end

    def call
      Result.new(
        success?: true,
        summary: {
          window_days: WINDOW_DAYS,
          starts_at: window_start.iso8601,
          ends_at: @now.iso8601,
          total_users: User.count,
          active_users: User.active_only.count,
          total_orders: orders_in_window.count,
          orders_by_status: orders_by_status,
          gross_volume_cents: orders_in_window.sum(:subtotal_cents),
        }
      )
    rescue StandardError
      Result.new(success?: false, error_code: :invalid_payload)
    end

    private

    def orders_in_window
      @orders_in_window ||= Order.where(created_at: window_start..@now)
    end

    def orders_by_status
      grouped = orders_in_window.group(:status).count

      Order::STATUSES.values.each_with_object({}) do |status, payload|
        payload[status] = grouped[status] || 0
      end
    end

    def window_start
      @window_start ||= @now - WINDOW_DAYS.days
    end
  end
end
