require "test_helper"
require "rack/test"
require "tempfile"

class ProfilePhotoUploadTest < ActionDispatch::IntegrationTest
  FakeS3Client = Struct.new(:error) do
    def put_object(**_kwargs)
      raise error if error

      true
    end
  end

  def create_user(email: "profile-photo-upload@example.com", password: "password123")
    Users::Create.call(
      email: email,
      password: password,
      password_confirmation: password
    ).user
  end

  def access_token_for(user, password: "password123")
    post "/auth/login", params: {
      email: user.email,
      password: password
    }, as: :json

    JSON.parse(response.body).dig("data", "access_token")
  end

  def build_uploaded_photo(filename: "avatar.jpg", content_type: "image/jpeg", body: "fake-image-data")
    tempfile = Tempfile.new(["upload", File.extname(filename)])
    tempfile.binmode
    tempfile.write(body)
    tempfile.rewind

    Rack::Test::UploadedFile.new(tempfile.path, content_type, true, original_filename: filename)
  end

  def with_singleton_method(receiver, method_name, callable)
    original_method = receiver.method(method_name)
    receiver.define_singleton_method(method_name, callable)

    yield
  ensure
    receiver.define_singleton_method(method_name, original_method)
  end

  test "uploads profile photo to R2 and persists public url" do
    user = create_user
    access_token = access_token_for(user)
    uploaded_file = build_uploaded_photo
    public_url = "https://public.example.r2.dev/profiles/#{user.profile.id}/fixed-uuid.jpg"
    fake_client = FakeS3Client.new(nil)

    with_singleton_method(Aws::S3::Client, :new, ->(**_kwargs) { fake_client }) do
      with_singleton_method(SecureRandom, :uuid, -> { "fixed-uuid" }) do
        post "/profile/photo", params: {
          photo: uploaded_file
        }, headers: {
          "Authorization" => "Bearer #{access_token}"
        }
      end
    end

    assert_response :success

    body = JSON.parse(response.body)
    assert_equal user.profile.id, body.dig("data", "id")
    assert_equal public_url, body.dig("data", "photo_url")

    user.profile.reload
    assert_equal public_url, user.profile.photo_url
  ensure
    uploaded_file&.tempfile&.close!
  end

  test "returns token invalido without authorization header" do
    uploaded_file = build_uploaded_photo

    post "/profile/photo", params: { photo: uploaded_file }

    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]
  ensure
    uploaded_file&.tempfile&.close!
  end

  test "returns token invalido for malformed bearer token" do
    uploaded_file = build_uploaded_photo

    post "/profile/photo", params: { photo: uploaded_file }, headers: {
      "Authorization" => "Bearer invalid-token"
    }

    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]
  ensure
    uploaded_file&.tempfile&.close!
  end

  test "returns token invalido for expired access token" do
    user = create_user(email: "expired-upload-token@example.com")
    uploaded_file = build_uploaded_photo
    expired_token = Auth::Jwt::Issuer.issue_access(
      user_id: user.id,
      now: 16.minutes.ago
    ).token

    post "/profile/photo", params: { photo: uploaded_file }, headers: {
      "Authorization" => "Bearer #{expired_token}"
    }

    assert_response :unauthorized
    assert_equal "token invalido", JSON.parse(response.body)["error"]
  ensure
    uploaded_file&.tempfile&.close!
  end

  test "returns payload invalido without photo file" do
    user = create_user(email: "missing-photo@example.com")
    access_token = access_token_for(user)

    post "/profile/photo", params: {}, headers: {
      "Authorization" => "Bearer #{access_token}"
    }

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_equal "foto obrigatoria", body["error"]
    assert_equal "missing_photo", body["code"]
  end

  test "returns payload invalido for unexpected multipart field" do
    user = create_user(email: "wrong-field-photo@example.com")
    access_token = access_token_for(user)
    uploaded_file = build_uploaded_photo

    post "/profile/photo", params: {
      avatar: uploaded_file
    }, headers: {
      "Authorization" => "Bearer #{access_token}"
    }

    assert_response :unprocessable_entity
    assert_equal "payload invalido", JSON.parse(response.body)["error"]
  ensure
    uploaded_file&.tempfile&.close!
  end

  test "returns payload invalido for file larger than 5MB" do
    user = create_user(email: "large-photo@example.com")
    access_token = access_token_for(user)
    uploaded_file = build_uploaded_photo(body: "a" * (5.megabytes + 1))

    post "/profile/photo", params: {
      photo: uploaded_file
    }, headers: {
      "Authorization" => "Bearer #{access_token}"
    }

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_equal "foto excede o limite de 5MB", body["error"]
    assert_equal "photo_too_large", body["code"]
  ensure
    uploaded_file&.tempfile&.close!
  end

  test "returns payload invalido for unsupported file type" do
    user = create_user(email: "unsupported-photo@example.com")
    access_token = access_token_for(user)
    uploaded_file = build_uploaded_photo(filename: "avatar.gif", content_type: "image/gif")

    post "/profile/photo", params: {
      photo: uploaded_file
    }, headers: {
      "Authorization" => "Bearer #{access_token}"
    }

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_equal "tipo de foto invalido", body["error"]
    assert_equal "invalid_photo_type", body["code"]
  ensure
    uploaded_file&.tempfile&.close!
  end

  test "returns falha ao enviar foto when upload provider fails and does not persist photo_url" do
    user = create_user(email: "provider-failure-photo@example.com")
    access_token = access_token_for(user)
    uploaded_file = build_uploaded_photo
    fake_client = FakeS3Client.new(StandardError.new("upload failed"))

    with_singleton_method(Aws::S3::Client, :new, ->(**_kwargs) { fake_client }) do
      post "/profile/photo", params: {
        photo: uploaded_file
      }, headers: {
        "Authorization" => "Bearer #{access_token}"
      }
    end

    assert_response :bad_gateway
    body = JSON.parse(response.body)
    assert_equal "falha ao enviar foto", body["error"]
    assert_equal "upload_failed", body["code"]

    user.profile.reload
    assert_nil user.profile.photo_url
  ensure
    uploaded_file&.tempfile&.close!
  end

  test "returns foto vazia for empty file" do
    user = create_user(email: "empty-photo@example.com")
    access_token = access_token_for(user)
    uploaded_file = build_uploaded_photo(body: "")

    post "/profile/photo", params: {
      photo: uploaded_file
    }, headers: {
      "Authorization" => "Bearer #{access_token}"
    }

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_equal "foto vazia", body["error"]
    assert_equal "empty_photo", body["code"]
  ensure
    uploaded_file&.tempfile&.close!
  end

  test "returns upload indisponivel when R2 configuration is missing" do
    user = create_user(email: "missing-config-photo@example.com")
    access_token = access_token_for(user)
    uploaded_file = build_uploaded_photo

    with_singleton_method(ENV, :[], ->(key) { key == "CLOUDFLARE_R2_BUCKET" ? nil : ENV.to_hash[key] }) do
      post "/profile/photo", params: {
        photo: uploaded_file
      }, headers: {
        "Authorization" => "Bearer #{access_token}"
      }
    end

    assert_response :internal_server_error
    body = JSON.parse(response.body)
    assert_equal "upload indisponivel", body["error"]
    assert_equal "invalid_configuration", body["code"]
  ensure
    uploaded_file&.tempfile&.close!
  end
end
