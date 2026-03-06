module Products
  class PublicProductSerializer
    class << self
      def call(product:)
        {
          id: product.id,
          title: product.title,
          description: product.description,
          price: product.price.to_s("F"),
          stock_quantity: product.stock_quantity,
        }
      end
    end
  end
end
