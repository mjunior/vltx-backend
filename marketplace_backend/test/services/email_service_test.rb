require "test_helper"

class EmailServiceTest < ActiveSupport::TestCase
  setup do
    @original_api_key = ENV["RESEND_API_KEY"]
    @original_from_email = ENV["RESEND_FROM_EMAIL"]
    @original_from_name = ENV["RESEND_FROM_NAME"]

    ENV["RESEND_API_KEY"] = "re_test_key"
    ENV["RESEND_FROM_EMAIL"] = "no-reply@example.com"
    ENV["RESEND_FROM_NAME"] = "Marketplace"
  end

  teardown do
    ENV["RESEND_API_KEY"] = @original_api_key
    ENV["RESEND_FROM_EMAIL"] = @original_from_email
    ENV["RESEND_FROM_NAME"] = @original_from_name
  end

  def with_stubbed_resend_send(callable)
    singleton = Resend::Emails.singleton_class
    original_method = Resend::Emails.method(:send)

    singleton.send(:define_method, :send, callable)
    yield
  ensure
    singleton.send(:define_method, :send, original_method)
  end

  test "sends password reset email with expected payload" do
    reset_link = "https://app.example.com/reset?token=abc123"
    payload = nil
    Resend.api_key = nil

    with_stubbed_resend_send(->(**kwargs) { payload = kwargs; { "id" => "email_123" } }) do
      result = EmailService.password_reset(to: "buyer@example.com", reset_link: reset_link)

      assert result.success?
      assert_equal "email_123", result.provider_id
    end

    assert_equal "re_test_key", Resend.api_key
    assert_equal "Marketplace <no-reply@example.com>", payload[:from]
    assert_equal "buyer@example.com", payload[:to]
    assert_equal "Redefina sua senha", payload[:subject]
    assert_includes payload[:html], reset_link
    assert_includes payload[:html], "Redefinir senha"
    assert_includes payload[:text], reset_link
    assert_includes payload[:text], "ignore este e-mail"
  end

  test "fails when resend configuration is missing" do
    ENV["RESEND_API_KEY"] = nil

    result = EmailService.password_reset(
      to: "buyer@example.com",
      reset_link: "https://app.example.com/reset?token=abc123"
    )

    assert_not result.success?
    assert_equal :invalid_configuration, result.error_code
    assert_nil result.provider_id
  end

  test "fails when resend raises an error" do
    with_stubbed_resend_send(->(**) { raise StandardError, "provider failure" }) do
      result = EmailService.password_reset(
        to: "buyer@example.com",
        reset_link: "https://app.example.com/reset?token=abc123"
      )

      assert_not result.success?
      assert_equal :email_delivery_failed, result.error_code
      assert_nil result.provider_id
    end
  end

  test "password reset only accepts to and reset_link keywords" do
    assert_raises(ArgumentError) do
      EmailService.password_reset(
        to: "buyer@example.com",
        reset_link: "https://app.example.com/reset?token=abc123",
        from: "custom@example.com"
      )
    end
  end

  test "builds html and text in pt br" do
    reset_link = "https://app.example.com/reset?token=abc123"
    payload = nil

    with_stubbed_resend_send(->(**kwargs) { payload = kwargs; { id: "email_456" } }) do
      EmailService.password_reset(to: "buyer@example.com", reset_link: reset_link)
    end

    assert_equal "Redefina sua senha", payload[:subject]
    assert_includes payload[:html], "Recebemos uma solicitacao para redefinir a senha da sua conta."
    assert_includes payload[:html], "Se voce nao solicitou a redefinicao de senha, ignore este e-mail."
    assert_includes payload[:text], "Acesse o link abaixo para continuar:"
    assert_includes payload[:text], reset_link
  end
end
