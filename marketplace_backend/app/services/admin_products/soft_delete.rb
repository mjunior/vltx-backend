module AdminProducts
  class SoftDelete
    Result = Struct.new(:success?, :product, :error_code, keyword_init: true)

    class << self
      def call(product_id:)
        new(product_id: product_id).call
      end
    end

    def initialize(product_id:)
      @product_id = product_id
    end

    def call
      product = Product.find_by(id: @product_id)
      return Result.new(success?: false, error_code: :not_found) unless product
      return Result.new(success?: false, error_code: :invalid_payload) if product.deleted_at.present?

      product.update!(deleted_at: Time.current)
      Result.new(success?: true, product: product)
    rescue StandardError
      Result.new(success?: false, error_code: :invalid_payload)
    end
  end
end
