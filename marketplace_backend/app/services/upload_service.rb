class UploadService
  Result = Struct.new(:success?, :public_url, :error_code, keyword_init: true)

  class << self
    def call(io:, content_type:, key:)
      new(io: io, content_type: content_type, key: key).call
    end
  end

  def initialize(io:, content_type:, key:)
    @io = io
    @content_type = content_type
    @key = key
  end

  def call
    return Result.new(success?: false, error_code: :invalid_configuration) unless configured?

    client.put_object(
      bucket: bucket_name,
      key: @key,
      body: @io,
      content_type: @content_type
    )

    Result.new(success?: true, public_url: build_public_url(@key))
  rescue StandardError
    Result.new(success?: false, error_code: :upload_failed)
  end

  private

  def configured?
    [bucket_name, endpoint, access_key_id, secret_access_key, public_base_url].all?(&:present?)
  end

  def client
    @client ||= Aws::S3::Client.new(
      access_key_id: access_key_id,
      secret_access_key: secret_access_key,
      endpoint: endpoint,
      region: "auto",
      force_path_style: true
    )
  end

  def bucket_name
    ENV["CLOUDFLARE_R2_BUCKET"]
  end

  def endpoint
    ENV["CLOUDFLARE_R2_ENDPOINT"]
  end

  def access_key_id
    ENV["CLOUDFLARE_R2_ACCESS_KEY_ID"]
  end

  def secret_access_key
    ENV["CLOUDFLARE_R2_SECRET_ACCESS_KEY"]
  end

  def public_base_url
    ENV["CLOUDFLARE_R2_PUBLIC_BASE_URL"]
  end

  def build_public_url(key)
    "#{public_base_url.to_s.chomp('/')}/#{key}"
  end
end
