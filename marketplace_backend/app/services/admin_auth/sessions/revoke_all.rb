module AdminAuth
  module Sessions
    class RevokeAll
      class << self
        def call(admin:)
          now = Time.current

          admin.admin_refresh_sessions.where(revoked_at: nil).update_all(
            revoked_at: now,
            updated_at: now
          )
        end
      end
    end
  end
end
