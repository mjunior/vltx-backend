require "test_helper"
require "securerandom"

module Profiles
  class UpdateProfileTest < ActiveSupport::TestCase
    def create_user(email: "profile-service@example.com")
      Users::Create.call(
        email: email,
        password: "password123",
        password_confirmation: "password123"
      ).user
    end

    test "updates name and address" do
      user = create_user

      result = UpdateProfile.call(user: user, params: {
        name: "Maria Souza",
        address: "Av Central, 10"
      })

      assert result.success?
      user.profile.reload
      assert_equal "Maria Souza", user.profile.full_name
      assert_equal "Av Central, 10", user.profile.address
    end

    test "keeps missing field unchanged" do
      user = create_user(email: "service-partial@example.com")
      user.profile.update!(full_name: "Nome Antigo", address: "Endereco Antigo")

      result = UpdateProfile.call(user: user, params: { name: "Nome Novo" })

      assert result.success?
      user.profile.reload
      assert_equal "Nome Novo", user.profile.full_name
      assert_equal "Endereco Antigo", user.profile.address
    end

    test "clears field when value is nil" do
      user = create_user(email: "service-clear@example.com")
      user.profile.update!(full_name: "Nome", address: "Endereco")

      result = UpdateProfile.call(user: user, params: { address: nil })

      assert result.success?
      user.profile.reload
      assert_nil user.profile.address
    end

    test "fails when params are empty" do
      user = create_user(email: "service-empty@example.com")

      result = UpdateProfile.call(user: user, params: {})

      assert_not result.success?
    end

    test "fails when params contain unknown fields" do
      user = create_user(email: "service-unknown@example.com")

      result = UpdateProfile.call(user: user, params: {
        name: "Nome",
        user_id: SecureRandom.uuid
      })

      assert_not result.success?
    end
  end
end
