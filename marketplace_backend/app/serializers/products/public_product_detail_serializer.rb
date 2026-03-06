module Products
  class PublicProductDetailSerializer
    class << self
      def call(product:)
        {
          id: product.id,
          title: product.title,
          description: product.description,
          price: product.price.to_f,
          stock_quantity: [product.stock_quantity.to_i, 0].max,
        }
      end
    end
  end
end
