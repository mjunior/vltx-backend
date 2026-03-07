module Carts
  class FindOrCreateActive
    Result = Struct.new(:success?, :cart, keyword_init: true)

    class << self
      def call(user:)
        new(user: user).call
      end
    end

    def initialize(user:)
      @user = user
    end

    def call
      return Result.new(success?: false) unless @user

      cart = find_or_create_active_cart
      return Result.new(success?: false) unless cart

      Result.new(success?: true, cart: cart)
    rescue StandardError
      Result.new(success?: false)
    end

    private

    def find_or_create_active_cart
      Cart.transaction do
        existing = active_cart
        return existing if existing

        Cart.create!(user: @user, status: :active)
      end
    rescue ActiveRecord::RecordNotUnique
      active_cart
    end

    def active_cart
      @user.carts.active.recent_first.first
    end
  end
end
