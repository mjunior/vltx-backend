require "test_helper"

module Ratings
  class CreateForOrderItemTest < ActiveSupport::TestCase
    def create_user(email: "ratings-service-buyer@example.com")
      Users::Create.call(
        email: email,
        password: "password123",
        password_confirmation: "password123"
      ).user
    end

    def create_product_for(user, attrs = {})
      defaults = {
        title: "Produto Ratings Service",
        description: "Descricao valida para ratings service",
        price: "18.00",
        stock_quantity: 6
      }

      Products::Create.call(user: user, params: defaults.merge(attrs)).product
    end

    def seed_wallet_for(user, amount_cents:)
      wallet = Wallet.find_or_create_by!(user: user)
      result = Wallets::Ledger::AppendTransaction.call(
        wallet: wallet,
        transaction_type: :credit,
        amount_cents: amount_cents,
        reference_type: "seed",
        reference_id: "seed-#{user.id}",
        operation_key: "seed-#{user.id}",
        metadata: { "source" => "seed" }
      )
      raise "seed failed" unless result.success?
    end

    def create_order_item(delivered: true, contested: false)
      buyer = create_user
      seller = create_user(email: "ratings-service-seller@example.com")
      product = create_product_for(seller)
      cart = Cart.create!(user: buyer, status: :active)
      CartItem.create!(cart: cart, product: product, quantity: 1)
      seed_wallet_for(buyer, amount_cents: 100_00)
      checkout = Carts::Finalize.call(user: buyer, params: { payment_method: "wallet" })
      order = Order.find(checkout.order_ids.first)

      if delivered
        Orders::Advance.call(order: order, actor: order.seller)
        Orders::Advance.call(order: order.reload, actor: order.seller)
        Orders::MarkDelivered.call(order: order.reload, actor: order.user)
        Orders::Contest.call(order: order.reload, actor: order.user) if contested
      end

      [buyer, order.reload.order_items.first.reload]
    end

    test "creates both product and seller ratings atomically" do
      buyer, order_item = create_order_item

      result = CreateForOrderItem.call(order_item: order_item, buyer: buyer, score: 5, comment: "Produto excelente")

      assert result.success?
      assert_equal order_item.id, result.product_rating.order_item_id
      assert_equal order_item.id, result.seller_rating.order_item_id
      assert_equal 1, ProductRating.where(order_item_id: order_item.id).count
      assert_equal 1, SellerRating.where(order_item_id: order_item.id).count
    end

    test "rejects duplicate rating for same order item" do
      buyer, order_item = create_order_item
      CreateForOrderItem.call(order_item: order_item, buyer: buyer, score: 4, comment: "Primeira nota")

      result = CreateForOrderItem.call(order_item: order_item.reload, buyer: buyer, score: 5, comment: "Segunda nota")

      assert_not result.success?
      assert_equal :invalid_payload, result.error_code
    end

    test "allows rating after contest because order was delivered before" do
      buyer, order_item = create_order_item(contested: true)

      result = CreateForOrderItem.call(order_item: order_item, buyer: buyer, score: 3, comment: "Entrega ok")

      assert result.success?
      assert_equal "contested", result.product_rating.order.status
    end

    test "rejects undelivered order item" do
      buyer, order_item = create_order_item(delivered: false)

      result = CreateForOrderItem.call(order_item: order_item, buyer: buyer, score: 2, comment: "Nao entregue")

      assert_not result.success?
      assert_equal :invalid_transition, result.error_code
    end
  end
end
