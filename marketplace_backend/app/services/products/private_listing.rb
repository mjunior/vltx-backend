module Products
  class PrivateListing
    Result = Struct.new(:success?, :products, :total, keyword_init: true)

    class << self
      def call(user:)
        new(user: user).call
      end
    end

    def initialize(user:)
      @user = user
    end

    def call
      return Result.new(success?: false, products: [], total: 0) unless @user

      relation = @user.products.not_deleted.order(created_at: :desc, id: :desc)
      Result.new(success?: true, products: relation.to_a, total: relation.count)
    rescue StandardError
      Result.new(success?: false, products: [], total: 0)
    end
  end
end
