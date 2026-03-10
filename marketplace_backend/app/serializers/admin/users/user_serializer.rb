class Admin::Users::UserSerializer
  class << self
    def call(user:)
      {
        id: user.id,
        email: user.email,
        active: user.active,
        verification_status: user.verification_status,
        created_at: user.created_at,
        updated_at: user.updated_at,
      }
    end
  end
end
