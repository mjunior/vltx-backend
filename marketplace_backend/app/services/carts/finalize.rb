require "bigdecimal"

module Carts
  class Finalize
    Result = Struct.new(:success?, :cart, :preparation, :error_code, keyword_init: true)

    ALLOWED_KEYS = %i[payment_method].freeze
    PAYMENT_METHOD_WALLET = "wallet".freeze

    class << self
      def call(user:, params:)
        new(user: user, params: params).call
      end
    end

    def initialize(user:, params:)
      @user = user
      @params = (params || {}).to_h.deep_symbolize_keys
    end

    def call
      return Result.new(success?: false, error_code: :invalid_payload) unless @user
      return Result.new(success?: false, error_code: :invalid_payload) unless valid_keys?
      return Result.new(success?: false, error_code: :invalid_payload) unless payment_method_wallet?

      cart = CartFinder.active_cart_for(user: @user)
      return Result.new(success?: false, error_code: :not_found) unless cart

      finalized = finalize_cart!(cart)
      return Result.new(success?: false, error_code: finalized[:error_code] || :invalid_payload) unless finalized[:success]

      Result.new(success?: true, cart: finalized[:cart], preparation: finalized[:preparation])
    rescue StandardError
      Result.new(success?: false, error_code: :invalid_payload)
    end

    private

    def valid_keys?
      return false if @params.empty?

      (@params.keys - ALLOWED_KEYS).empty? && @params.key?(:payment_method)
    end

    def payment_method_wallet?
      @params[:payment_method].to_s == PAYMENT_METHOD_WALLET
    end

    def finalize_cart!(cart)
      payload = nil
      error_code = nil

      Cart.transaction do
        locked_cart = Cart.lock.find_by(id: cart.id, user_id: @user.id, status: Cart.statuses[:active])
        unless locked_cart
          error_code = :not_found
          raise ActiveRecord::Rollback
        end

        if locked_cart.cart_items.lock.none?
          error_code = :invalid_payload
          raise ActiveRecord::Rollback
        end

        locked_cart.update!(status: :finished)
        preparation_result = Orders::PrepareFromCart.call(cart: locked_cart)
        unless preparation_result.success?
          error_code = :invalid_payload
          raise ActiveRecord::Rollback
        end

        movement_result = Wallets::Operations::ApplyMovement.call(
          wallet: wallet_for(user: @user),
          transaction_type: :debit,
          trusted_amount_cents: subtotal_cents(preparation_result.preparation),
          reference_type: "cart_checkout",
          reference_id: locked_cart.id,
          operation_key: "checkout:#{locked_cart.id}",
          metadata: {
            "checkout_id" => locked_cart.id,
            "source" => "cart_checkout",
          }
        )
        unless movement_result.success?
          error_code = if movement_result.error_code == :not_found
                         :not_found
                       elsif movement_result.error_code == :insufficient_funds
                         :insufficient_funds
                       else
                         :invalid_payload
                       end
          raise ActiveRecord::Rollback
        end

        payload = {
          cart: locked_cart.reload,
          preparation: preparation_result.preparation,
        }
      end

      return { success: true, cart: payload[:cart], preparation: payload[:preparation] } if payload

      { success: false, error_code: error_code || :invalid_payload }
    end

    def subtotal_cents(preparation)
      subtotal = preparation[:subtotal].to_s
      (BigDecimal(subtotal) * 100).to_i
    end

    def wallet_for(user:)
      Wallet.find_or_create_by!(user: user)
    end
  end
end
