require "test_helper"

module Products
  class PublicListingTest < ActiveSupport::TestCase
    def create_user(email: "public-listing-service@example.com")
      Users::Create.call(
        email: email,
        password: "password123",
        password_confirmation: "password123"
      ).user
    end

    def create_product_for(user, title:, description:, price:, active: true, deleted_at: nil)
      product = Products::Create.call(user: user, params: {
        title: title,
        description: description,
        price: price,
        stock_quantity: 3
      }).product
      product.update!(active: active, deleted_at: deleted_at)
      product
    end

    test "returns only public visible products" do
      user = create_user
      visible = create_product_for(user, title: "Notebook", description: "Notebook gamer", price: "4000.00")
      create_product_for(user, title: "Inativo", description: "Nao deve aparecer", price: "100.00", active: false)
      create_product_for(user, title: "Deletado", description: "Nao deve aparecer", price: "150.00", deleted_at: Time.current)

      result = PublicListing.call(params: {})

      assert result.success?
      assert_equal 1, result.total
      assert_equal [visible.id], result.products.map(&:id)
    end

    test "filters by query across title and description" do
      user = create_user(email: "query-service@example.com")
      title_hit = create_product_for(user, title: "Cadeira Premium", description: "Conforto total", price: "800.00")
      desc_hit = create_product_for(user, title: "Mesa", description: "Ideal para cadeira gamer", price: "500.00")
      create_product_for(user, title: "Mouse", description: "Sem relacao", price: "100.00")

      result = PublicListing.call(params: { q: "cadeira" })

      assert result.success?
      assert_equal [title_hit.id, desc_hit.id].sort, result.products.map(&:id).sort
    end

    test "filters by price range and validates invalid params" do
      user = create_user(email: "price-service@example.com")
      create_product_for(user, title: "Produto 1", description: "Faixa de preco baixa", price: "100.00")
      in_range = create_product_for(user, title: "Produto 2", description: "Faixa de preco media", price: "250.00")
      create_product_for(user, title: "Produto 3", description: "Faixa de preco alta", price: "500.00")

      filtered = PublicListing.call(params: { min_price: "200", max_price: "300" })
      invalid = PublicListing.call(params: { min_price: "aaa" })

      assert filtered.success?
      assert_equal [in_range.id], filtered.products.map(&:id)
      assert_not invalid.success?
      assert_equal :invalid_payload, invalid.error_code
    end
  end
end
