require "test_helper"

module SellerReceivables
  class ReadSummaryTest < ActiveSupport::TestCase
    def create_user(email: "seller-receivables-summary-buyer@example.com")
      Users::Create.call(
        email: email,
        password: "password123",
        password_confirmation: "password123"
      ).user
    end

    def create_receivable_for(seller:, buyer:, amount_cents:, status: :pending)
      cart = Cart.create!(user: buyer, status: :finished)
      checkout_group = CheckoutGroup.create!(
        buyer: buyer,
        source_cart: cart,
        currency: "BRL",
        total_items: 1,
        subtotal_cents: amount_cents
      )
      order = Order.create!(
        user: buyer,
        seller: seller,
        source_cart: cart,
        checkout_group: checkout_group,
        status: :paid,
        currency: "BRL",
        total_items: 1,
        subtotal_cents: amount_cents
      )

      SellerReceivable.create!(
        order: order,
        seller: seller,
        buyer: buyer,
        checkout_group: checkout_group,
        status: status,
        amount_cents: amount_cents
      )
    end

    test "returns pending total and list scoped to seller" do
      seller = create_user(email: "seller-receivables-summary-seller@example.com")
      other_seller = create_user(email: "seller-receivables-summary-other-seller@example.com")
      buyer = create_user
      create_receivable_for(seller: seller, buyer: buyer, amount_cents: 30_00, status: :pending)
      create_receivable_for(seller: seller, buyer: buyer, amount_cents: 20_00, status: :credited)
      create_receivable_for(seller: other_seller, buyer: buyer, amount_cents: 90_00, status: :pending)

      result = ReadSummary.call(seller: seller)

      assert result.success?
      assert_equal seller.id, result.summary[:seller_id]
      assert_equal 30_00, result.summary[:pending_total_cents]
      assert_equal "30.00", result.summary[:pending_total]
      assert_equal 2, result.summary[:receivables].length
      assert_equal ["credited", "pending"].sort, result.summary[:receivables].map { |r| r[:status] }.sort
      assert result.summary[:receivables].all? { |r| r[:buyer_id] == buyer.id }
    end

    test "rejects invalid payload when seller is missing" do
      result = ReadSummary.call(seller: nil)

      assert_not result.success?
      assert_equal :invalid_payload, result.error_code
    end
  end
end
