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
      return Result.new(success?: false, error_code: :invalid_payload) unless finalized

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

      Cart.transaction do
        locked_cart = Cart.lock.find_by(id: cart.id, user_id: @user.id, status: Cart.statuses[:active])
        return nil unless locked_cart
        return nil if locked_cart.cart_items.lock.none?

        locked_cart.update!(status: :finished)
        preparation_result = Orders::PrepareFromCart.call(cart: locked_cart)
        return nil unless preparation_result.success?

        payload = {
          cart: locked_cart.reload,
          preparation: preparation_result.preparation,
        }
      end

      payload
    end
  end
end
