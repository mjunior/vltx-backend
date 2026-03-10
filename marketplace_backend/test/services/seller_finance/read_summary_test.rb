require "test_helper"

module SellerFinance
  class ReadSummaryTest < ActiveSupport::TestCase
    def create_user(email: "seller-finance-buyer@example.com")
      Users::Create.call(
        email: email,
        password: "password123",
        password_confirmation: "password123"
      ).user
    end

    def create_product_for(user, attrs = {})
      defaults = {
        title: "Produto Finance",
        description: "Descricao valida para seller finance",
        price: "25.00",
        stock_quantity: 8
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

    def create_order_flow_for(seller:, buyer:, delivered: false)
      product = create_product_for(seller)
      cart = Cart.create!(user: buyer, status: :active)
      CartItem.create!(cart: cart, product: product, quantity: 1)
      seed_wallet_for(buyer, amount_cents: 200_00)
      checkout = Carts::Finalize.call(user: buyer, params: { payment_method: "wallet" })
      raise "checkout failed" unless checkout.success?
      order = Order.find(checkout.order_ids.first)
      return order unless delivered

      Orders::Advance.call(order: order, actor: order.seller)
      Orders::Advance.call(order: order.reload, actor: order.seller)
      Orders::MarkDelivered.call(order: order.reload, actor: order.user)
      order.reload
    end

    test "returns pending receivables and credited history scoped to seller" do
      seller = create_user(email: "seller-finance-seller@example.com")
      buyer = create_user
      other_seller = create_user(email: "seller-finance-other-seller@example.com")
      pending_order = create_order_flow_for(seller: seller, buyer: buyer)
      credited_order = create_order_flow_for(seller: seller, buyer: create_user(email: "seller-finance-second-buyer@example.com"), delivered: true)
      create_order_flow_for(seller: other_seller, buyer: create_user(email: "seller-finance-third-buyer@example.com"), delivered: true)

      result = ReadSummary.call(seller: seller)

      assert result.success?
      assert_equal seller.id, result.summary[:seller_id]
      assert_equal pending_order.subtotal_cents, result.summary[:pending_total_cents]
      assert_equal credited_order.subtotal_cents, result.summary[:credited_total_cents]
      assert_equal [pending_order.id], result.summary[:pending_receivables].map { |row| row[:order_id] }
      assert_equal [credited_order.id], result.summary[:transaction_history].map { |row| row[:order_id] }
      assert_equal "paid", result.summary[:pending_receivables].first[:order_status]
      assert_equal "delivered", result.summary[:transaction_history].first[:order_status]
    end

    test "returns zeros when seller has no wallet credits yet" do
      seller = create_user(email: "seller-finance-empty@example.com")

      result = ReadSummary.call(seller: seller)

      assert result.success?
      assert_equal 0, result.summary[:pending_total_cents]
      assert_equal 0, result.summary[:credited_total_cents]
      assert_empty result.summary[:pending_receivables]
      assert_empty result.summary[:transaction_history]
    end

    test "includes contest reversal debit in seller transaction history" do
      seller = create_user(email: "seller-finance-reversal-seller@example.com")
      buyer = create_user(email: "seller-finance-reversal-buyer@example.com")
      order = create_order_flow_for(seller: seller, buyer: buyer, delivered: true)
      Orders::Contest.call(order: order, actor: order.user)
      Orders::ApproveContestation.call(order: order.reload, actor: order.seller)

      result = ReadSummary.call(seller: seller)

      assert result.success?
      assert_equal ["credit", "debit"].sort, result.summary[:transaction_history].map { |row| row[:transaction_type] }.sort
      assert_equal "refunded", result.summary[:transaction_history].find { |row| row[:transaction_type] == "debit" }[:order_status]
    end
  end
end
