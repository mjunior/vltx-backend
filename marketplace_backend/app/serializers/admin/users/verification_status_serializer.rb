class Admin::Users::VerificationStatusSerializer
  class << self
    def call(user:)
      {
        id: user.id,
        email: user.email,
        verification_status: user.verification_status,
      }
    end
  end
end
