class Admin::Products::ProductSerializer
  class << self
    def call(product:)
      {
        id: product.id,
        title: product.title,
        description: product.description,
        price: product.price.to_s("F"),
        price_cents: (product.price * 100).to_i,
        stock_quantity: product.stock_quantity,
        active: product.active,
        deleted_at: product.deleted_at,
        seller_id: product.user_id,
        created_at: product.created_at,
        updated_at: product.updated_at,
      }
    end
  end
end
