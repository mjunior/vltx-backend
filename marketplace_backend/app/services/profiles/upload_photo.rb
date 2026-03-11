require "securerandom"

module Profiles
  class UploadPhoto
    Result = Struct.new(:success?, :profile, :error_code, keyword_init: true)

    MAX_FILE_SIZE = 5.megabytes
    ALLOWED_CONTENT_TYPES = {
      "image/jpeg" => "jpg",
      "image/png" => "png",
      "image/webp" => "webp",
    }.freeze

    class << self
      def call(user:, photo:)
        new(user: user, photo: photo).call
      end
    end

    def initialize(user:, photo:)
      @user = user
      @photo = photo
    end

    def call
      return Result.new(success?: false, error_code: :profile_not_found) unless @user&.profile

      validation_error = validate_photo
      return Result.new(success?: false, error_code: validation_error) if validation_error

      upload_result = UploadService.call(
        io: @photo.tempfile,
        content_type: @photo.content_type,
        key: object_key
      )
      return Result.new(success?: false, error_code: upload_result.error_code) unless upload_result.success?
      return Result.new(success?: false, error_code: :profile_update_failed) unless @user.profile.update(photo_url: upload_result.public_url)

      Result.new(success?: true, profile: @user.profile)
    rescue StandardError
      Result.new(success?: false, error_code: :upload_failed)
    end

    private

    def validate_photo
      return :missing_photo unless @photo
      return :missing_photo unless upload_like_object?
      return :invalid_photo_type unless ALLOWED_CONTENT_TYPES.key?(@photo.content_type)
      return :empty_photo unless @photo.size.to_i.positive?
      return :photo_too_large if @photo.size.to_i > MAX_FILE_SIZE

      nil
    end

    def upload_like_object?
      @photo.respond_to?(:tempfile) &&
        @photo.respond_to?(:content_type) &&
        @photo.respond_to?(:size)
    end

    def object_key
      extension = ALLOWED_CONTENT_TYPES.fetch(@photo.content_type)
      "profiles/#{@user.profile.id}/#{SecureRandom.uuid}.#{extension}"
    end
  end
end
