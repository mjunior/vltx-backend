module Auth
  module Sessions
    class RevokeAll
      class << self
        def call(user:)
          now = Time.current

          user.refresh_sessions.where(revoked_at: nil).update_all(
            revoked_at: now,
            updated_at: now
          )
        end
      end
    end
  end
end
