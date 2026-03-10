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

    def create_checkout_group_for(buyer, cart:, total_items:, subtotal_cents:)
      CheckoutGroup.create!(
        buyer: buyer,
        source_cart: cart,
        currency: "BRL",
        total_items: total_items,
        subtotal_cents: subtotal_cents
      )
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
      checkout_group = create_checkout_group_for(buyer, cart: cart, total_items: 5, subtotal_cents: 80_00)

      result = CreateFromCart.call(cart: cart, buyer: buyer, checkout_group: checkout_group)

      assert result.success?
      assert_equal 2, result.orders.length
      assert_equal 2, result.summary[:orders_count]
      assert_equal checkout_group.id, result.summary[:checkout_group_id]
      assert_equal 5, result.summary[:total_items]
      assert_equal 80_00, result.summary[:subtotal_cents]
      assert_equal [product_a.user_id, product_b.user_id].sort, result.orders.map(&:seller_id).sort
      assert result.orders.all? { |order| order.checkout_group_id == checkout_group.id }
      assert_equal 2, SellerReceivable.count
      assert_equal [30_00, 50_00], SellerReceivable.order(:amount_cents).pluck(:amount_cents)
      assert_equal ["pending", "pending"], SellerReceivable.order(:amount_cents).pluck(:status)
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
      checkout_group = create_checkout_group_for(buyer, cart: cart, total_items: 3, subtotal_cents: 60_00)

      result = CreateFromCart.call(cart: cart, buyer: buyer, checkout_group: checkout_group)

      assert_not result.success?
      assert_equal :invalid_payload, result.error_code
      assert_equal 0, Order.count
      assert_equal 0, OrderItem.count
      assert_equal 0, SellerReceivable.count
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
      checkout_group = create_checkout_group_for(other, cart: cart, total_items: 1, subtotal_cents: 40_00)

      result = CreateFromCart.call(cart: cart, buyer: buyer, checkout_group: checkout_group)

      assert_not result.success?
      assert_equal :invalid_payload, result.error_code
    end

    test "does not duplicate orders or decrement stock twice on retry for the same cart" do
      buyer = create_user(email: "orders-create-retry-buyer@example.com")
      seller = create_user(email: "orders-create-retry-seller@example.com")
      product = create_product_for(seller, price: "25.00", stock_quantity: 5)
      cart = Cart.create!(user: buyer, status: :active)
      CartItem.create!(cart: cart, product: product, quantity: 2)
      checkout_group = create_checkout_group_for(buyer, cart: cart, total_items: 2, subtotal_cents: 50_00)

      first = CreateFromCart.call(cart: cart, buyer: buyer, checkout_group: checkout_group)
      second = CreateFromCart.call(cart: cart, buyer: buyer, checkout_group: checkout_group)

      assert first.success?
      assert_not second.success?
      assert_equal :invalid_payload, second.error_code
      assert_equal 1, Order.count
      assert_equal 1, OrderItem.count
      assert_equal 1, SellerReceivable.count
      assert_equal 3, product.reload.stock_quantity
    end

    test "returns invalid payload when checkout group does not match cart context" do
      buyer = create_user(email: "orders-create-group-buyer@example.com")
      seller = create_user(email: "orders-create-group-seller@example.com")
      other_cart = Cart.create!(user: buyer, status: :finished)
      cart = Cart.create!(user: buyer, status: :active)
      product = create_product_for(seller)
      CartItem.create!(cart: cart, product: product, quantity: 1)
      checkout_group = create_checkout_group_for(buyer, cart: other_cart, total_items: 1, subtotal_cents: 40_00)

      result = CreateFromCart.call(cart: cart, buyer: buyer, checkout_group: checkout_group)

      assert_not result.success?
      assert_equal :invalid_payload, result.error_code
    end
  end
end
