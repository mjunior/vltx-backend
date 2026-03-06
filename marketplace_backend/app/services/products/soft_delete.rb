module Products
  class SoftDelete
    Result = Struct.new(:success?, :product, :error_code, keyword_init: true)

    class << self
      def call(user:, product_id:)
        new(user: user, product_id: product_id).call
      end
    end

    def initialize(user:, product_id:)
      @user = user
      @product_id = product_id
    end

    def call
      product = find_owned_product
      return Result.new(success?: false, error_code: :not_found) unless product

      return Result.new(success?: false, error_code: :invalid_payload) unless product.update(deleted_at: Time.current)

      Result.new(success?: true, product: product)
    rescue StandardError
      Result.new(success?: false, error_code: :invalid_payload)
    end

    private

    def find_owned_product
      return nil unless @user

      @user.products.not_deleted.find_by(id: @product_id)
    end
  end
end
