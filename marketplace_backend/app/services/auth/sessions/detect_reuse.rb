module Auth
  module Sessions
    class DetectReuse
      Result = Struct.new(:reuse_detected, :user_id, keyword_init: true)

      class << self
        def call(refresh_jti:)
          session = RefreshSession.find_by(refresh_jti: refresh_jti)
          return Result.new(reuse_detected: false, user_id: nil) unless session
          return Result.new(reuse_detected: false, user_id: session.user_id) unless session.revoked?

          RevokeAll.call(user: session.user)
          Result.new(reuse_detected: true, user_id: session.user_id)
        end
      end
    end
  end
end
