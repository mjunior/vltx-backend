module Profiles
  class ProfileSerializer
    class << self
      def call(profile:)
        {
          data: {
            id: profile.id,
            name: profile.full_name,
            address: profile.address,
          },
        }
      end
    end
  end
end
