module Products
  class PrivateProductSerializer
    class << self
      def call(product:)
        {
          data: {
            id: product.id,
            title: product.title,
            description: product.description,
            price: product.price.to_s("F"),
            stock_quantity: product.stock_quantity,
            active: product.active,
            deleted_at: product.deleted_at,
          },
        }
      end
    end
  end
end
