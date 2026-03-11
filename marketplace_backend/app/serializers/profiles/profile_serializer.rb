module Profiles
  class ProfileSerializer
    class << self
      def call(profile:)
        {
          data: {
            id: profile.id,
            name: profile.full_name,
            address: profile.address,
            photo_url: profile.photo_url,
          },
        }
      end
    end
  end
end
