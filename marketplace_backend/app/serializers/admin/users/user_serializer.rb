class Admin::Users::UserSerializer
  class << self
    def call(user:)
      profile = user.profile
      wallet = user.wallet

      {
        id: user.id,
        email: user.email,
        active: user.active,
        verification_status: user.verification_status,
        profile: {
          id: profile&.id,
          name: profile&.full_name,
          address: profile&.address,
          photo_url: profile&.photo_url,
        },
        wallet: {
          id: wallet&.id,
          current_balance_cents: wallet&.current_balance_cents || 0,
        },
        created_at: user.created_at,
        updated_at: user.updated_at,
      }
    end
  end
end
