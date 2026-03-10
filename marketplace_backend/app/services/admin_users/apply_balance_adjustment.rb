module AdminUsers
  class ApplyBalanceAdjustment
    Result = Struct.new(:success?, :user, :wallet, :transaction, :error_code, keyword_init: true)

    ALLOWED_TYPES = %w[credit debit].freeze

    class << self
      def call(user_id:, admin:, params:)
        new(user_id: user_id, admin: admin, params: params).call
      end
    end

    def initialize(user_id:, admin:, params:)
      @user_id = user_id
      @admin = admin
      @params = params || {}
    end

    def call
      user = User.find_by(id: @user_id)
      return Result.new(success?: false, error_code: :not_found) unless user
      return Result.new(success?: false, error_code: :invalid_payload) unless user.active?

      normalized = normalize_params
      return Result.new(success?: false, error_code: :invalid_payload) unless valid_payload?(normalized)

      wallet = Wallet.find_or_create_by!(user: user)
      movement_result = Wallets::Operations::ApplyMovement.call(
        wallet: wallet,
        transaction_type: normalized[:transaction_type],
        trusted_amount_cents: normalized[:amount_cents],
        reference_type: "admin_adjustment",
        reference_id: SecureRandom.uuid,
        operation_key: "admin-adjustment-#{user.id}-#{SecureRandom.uuid}",
        metadata: adjustment_metadata(normalized)
      )

      return Result.new(success?: false, error_code: movement_result.error_code || :invalid_payload) unless movement_result.success?

      Result.new(
        success?: true,
        user: user,
        wallet: wallet.reload,
        transaction: movement_result.transaction
      )
    rescue StandardError
      Result.new(success?: false, error_code: :invalid_payload)
    end

    private

    def normalize_params
      raw = @params.to_h.deep_symbolize_keys
      raw[:transaction_type] = raw[:transaction_type].to_s.strip
      raw[:reason] = raw[:reason].to_s.strip
      raw
    end

    def valid_payload?(normalized)
      ALLOWED_TYPES.include?(normalized[:transaction_type]) &&
        normalized[:amount_cents].is_a?(Integer) &&
        normalized[:amount_cents].positive? &&
        normalized[:reason].present?
    end

    def adjustment_metadata(normalized)
      {
        "source" => "admin_adjustment",
        "reason" => normalized[:reason],
        "note" => "admin:#{@admin.email}",
      }
    end
  end
end
