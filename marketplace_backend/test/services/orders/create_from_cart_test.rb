require "test_helper"

module Orders
  class CreateFromCartTest < ActiveSupport::TestCase
    def create_user(email: "orders-create-from-cart@example.com")
      Users::Create.call(
        email: email,
        password: "password123",
        password_confirmation: "password123"
      ).user
    end

    def create_product_for(user, attrs = {})
      defaults = {
        title: "Produto Order Create",
        description: "Descricao valida para criacao de pedido",
        price: "40.00",
        stock_quantity: 8,
      }

      Products::Create.call(user: user, params: defaults.merge(attrs)).product
    end

    test "creates one order per seller and decrements stock" do
      buyer = create_user
      seller_a = create_user(email: "orders-create-seller-a@example.com")
      seller_b = create_user(email: "orders-create-seller-b@example.com")
      product_a = create_product_for(seller_a, title: "Produto A", price: "25.00", stock_quantity: 5)
      product_b = create_product_for(seller_b, title: "Produto B", price: "10.00", stock_quantity: 7)
      cart = Cart.create!(user: buyer, status: :active)
      CartItem.create!(cart: cart, product: product_a, quantity: 2)
      CartItem.create!(cart: cart, product: product_b, quantity: 3)

      result = CreateFromCart.call(cart: cart, buyer: buyer)

      assert result.success?
      assert_equal 2, result.orders.length
      assert_equal 2, result.summary[:orders_count]
      assert_equal 5, result.summary[:total_items]
      assert_equal 80_00, result.summary[:subtotal_cents]
      assert_equal [product_a.user_id, product_b.user_id].sort, result.orders.map(&:seller_id).sort
      assert_equal 3, product_a.reload.stock_quantity
      assert_equal 4, product_b.reload.stock_quantity
    end

    test "fails closed when any item lacks stock" do
      buyer = create_user(email: "orders-create-insufficient-buyer@example.com")
      seller_a = create_user(email: "orders-create-insufficient-seller-a@example.com")
      seller_b = create_user(email: "orders-create-insufficient-seller-b@example.com")
      product_a = create_product_for(seller_a, title: "Produto A", price: "25.00", stock_quantity: 1)
      product_b = create_product_for(seller_b, title: "Produto B", price: "10.00", stock_quantity: 7)
      cart = Cart.create!(user: buyer, status: :active)
      CartItem.create!(cart: cart, product: product_a, quantity: 2)
      CartItem.create!(cart: cart, product: product_b, quantity: 1)

      result = CreateFromCart.call(cart: cart, buyer: buyer)

      assert_not result.success?
      assert_equal :invalid_payload, result.error_code
      assert_equal 0, Order.count
      assert_equal 0, OrderItem.count
      assert_equal 1, product_a.reload.stock_quantity
      assert_equal 7, product_b.reload.stock_quantity
    end

    test "returns invalid payload when cart ownership does not match buyer" do
      buyer = create_user(email: "orders-create-ownership-buyer@example.com")
      other = create_user(email: "orders-create-ownership-other@example.com")
      seller = create_user(email: "orders-create-ownership-seller@example.com")
      product = create_product_for(seller)
      cart = Cart.create!(user: other, status: :active)
      CartItem.create!(cart: cart, product: product, quantity: 1)

      result = CreateFromCart.call(cart: cart, buyer: buyer)

      assert_not result.success?
      assert_equal :invalid_payload, result.error_code
    end

    test "does not duplicate orders or decrement stock twice on retry for the same cart" do
      buyer = create_user(email: "orders-create-retry-buyer@example.com")
      seller = create_user(email: "orders-create-retry-seller@example.com")
      product = create_product_for(seller, price: "25.00", stock_quantity: 5)
      cart = Cart.create!(user: buyer, status: :active)
      CartItem.create!(cart: cart, product: product, quantity: 2)

      first = CreateFromCart.call(cart: cart, buyer: buyer)
      second = CreateFromCart.call(cart: cart, buyer: buyer)

      assert first.success?
      assert_not second.success?
      assert_equal :invalid_payload, second.error_code
      assert_equal 1, Order.count
      assert_equal 1, OrderItem.count
      assert_equal 3, product.reload.stock_quantity
    end
  end
end
