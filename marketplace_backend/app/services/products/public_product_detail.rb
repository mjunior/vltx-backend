module Products
  class PublicProductDetail
    Result = Struct.new(:success?, :product, keyword_init: true)
    UUID_FORMAT = /\A[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i

    class << self
      def call(id:)
        new(id: id).call
      end
    end

    def initialize(id:)
      @id = id.to_s
    end

    def call
      return Result.new(success?: false) unless valid_uuid?(@id)

      product = Product.public_visible.find_by(id: @id)
      return Result.new(success?: false) unless product

      Result.new(success?: true, product: product)
    rescue StandardError
      Result.new(success?: false)
    end

    private

    def valid_uuid?(value)
      value.match?(UUID_FORMAT)
    end
  end
end
