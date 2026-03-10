module AdminAuth
  module Sessions
    class DetectReuse
      Result = Struct.new(:reuse_detected, :admin_id, keyword_init: true)

      class << self
        def call(refresh_jti:, admin_id: nil, refresh_token: nil)
          session = AdminRefreshSession.find_by(refresh_jti: refresh_jti)
          return handle_missing_session(admin_id) unless session

          return trigger_incident(session.admin) if session.revoked?

          if refresh_token.present?
            expected_hash = TokenDigest.call(refresh_token)
            return trigger_incident(session.admin) if session.refresh_token_hash != expected_hash
          end

          Result.new(reuse_detected: false, admin_id: session.admin_id)
        end

        private

        def handle_missing_session(admin_id)
          admin = Admin.find_by(id: admin_id)
          return Result.new(reuse_detected: false, admin_id: nil) unless admin

          trigger_incident(admin)
        end

        def trigger_incident(admin)
          RevokeAll.call(admin: admin)
          Result.new(reuse_detected: true, admin_id: admin.id)
        end
      end
    end
  end
end
