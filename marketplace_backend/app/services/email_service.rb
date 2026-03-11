require "erb"

class EmailService
  Result = Struct.new(:success?, :provider_id, :error_code, keyword_init: true)

  class << self
    def password_reset(to:, reset_link:)
      new.password_reset(to:, reset_link:)
    end
  end

  def password_reset(to:, reset_link:)
    send_email(
      to: to,
      subject: "Redefina sua senha",
      html: password_reset_html(reset_link: reset_link),
      text: password_reset_text(reset_link: reset_link)
    )
  end

  private

  def send_email(to:, subject:, html:, text:)
    return Result.new(success?: false, error_code: :invalid_configuration) unless configured?

    Resend.api_key = api_key

    response = Resend::Emails.send(
      {
      from: from_address,
      to: to,
      subject: subject,
      html: html,
      text: text
      }
    )

    Result.new(success?: true, provider_id: extract_provider_id(response))
  rescue StandardError => error
    log_delivery_failure(error)
    Result.new(success?: false, error_code: :email_delivery_failed)
  end

  def configured?
    api_key.present? && from_email.present?
  end

  def api_key
    ENV["RESEND_API_KEY"].to_s.strip
  end

  def from_email
    ENV["RESEND_FROM_EMAIL"].to_s.strip
  end

  def from_name
    ENV["RESEND_FROM_NAME"].to_s.strip
  end

  def from_address
    return from_email if from_name.blank?

    "#{from_name} <#{from_email}>"
  end

  def extract_provider_id(response)
    return response[:id] if response.respond_to?(:[]) && response[:id].present?
    return response["id"] if response.respond_to?(:[]) && response["id"].present?

    nil
  end

  def log_delivery_failure(error)
    Rails.logger.warn(
      {
        event: "email_service.delivery_failed",
        error_class: error.class.name,
        message: error.message
      }.to_json
    )
  rescue StandardError
    nil
  end

  def password_reset_html(reset_link:)
    escaped_link = ERB::Util.html_escape(reset_link)

    <<~HTML
      <div style="background-color:#f4f1ea;padding:24px;font-family:Arial,sans-serif;color:#1f2933;">
        <div style="max-width:560px;margin:0 auto;background-color:#ffffff;border-radius:16px;padding:32px;border:1px solid #e5ded3;">
          <h1 style="margin:0 0 16px;font-size:24px;line-height:1.3;color:#111827;">Redefina sua senha</h1>
          <p style="margin:0 0 16px;font-size:16px;line-height:1.6;">Recebemos uma solicitacao para redefinir a senha da sua conta.</p>
          <p style="margin:0 0 24px;font-size:16px;line-height:1.6;">Para continuar, clique no botao abaixo:</p>
          <p style="margin:0 0 24px;">
            <a href="#{escaped_link}" style="display:inline-block;background-color:#111827;color:#ffffff;text-decoration:none;padding:14px 24px;border-radius:999px;font-weight:bold;">
              Redefinir senha
            </a>
          </p>
          <p style="margin:0 0 16px;font-size:14px;line-height:1.6;color:#4b5563;">
            Se o botao nao funcionar, copie e cole este link no navegador:
          </p>
          <p style="margin:0 0 24px;font-size:14px;line-height:1.6;word-break:break-all;">
            <a href="#{escaped_link}" style="color:#0f766e;">#{escaped_link}</a>
          </p>
          <p style="margin:0;font-size:14px;line-height:1.6;color:#6b7280;">
            Se voce nao solicitou a redefinicao de senha, ignore este e-mail.
          </p>
        </div>
      </div>
    HTML
  end

  def password_reset_text(reset_link:)
    <<~TEXT
      Redefina sua senha

      Recebemos uma solicitacao para redefinir a senha da sua conta.

      Acesse o link abaixo para continuar:
      #{reset_link}

      Se voce nao solicitou a redefinicao de senha, ignore este e-mail.
    TEXT
  end
end
