require "test_helper"

module Orders
  class ApproveContestationTest < ActiveSupport::TestCase
    def create_user(email: "orders-approve-contest-buyer@example.com")
      Users::Create.call(
        email: email,
        password: "password123",
        password_confirmation: "password123"
      ).user
    end

    def create_product_for(user, attrs = {})
      defaults = {
        title: "Produto Approve Contest",
        description: "Descricao valida para approve contest",
        price: "60.00",
        stock_quantity: 4
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

    def create_contested_order
      buyer = create_user
      seller = create_user(email: "orders-approve-contest-seller@example.com")
      product = create_product_for(seller)
      cart = Cart.create!(user: buyer, status: :active)
      CartItem.create!(cart: cart, product: product, quantity: 1)
      seed_wallet_for(buyer, amount_cents: 200_00)
      checkout = Carts::Finalize.call(user: buyer, params: { payment_method: "wallet" })
      raise "checkout failed" unless checkout.success?
      order = Order.find(checkout.order_ids.first)
      Orders::Advance.call(order: order, actor: order.seller)
      Orders::Advance.call(order: order.reload, actor: order.seller)
      Orders::MarkDelivered.call(order: order.reload, actor: order.user)
      Orders::Contest.call(order: order.reload, actor: order.user)
      order.reload
    end

    test "seller approves contested order and creates refund plus seller reversal" do
      order = create_contested_order
      buyer_wallet = Wallet.find_by!(user: order.user)
      seller_wallet = Wallet.find_by!(user: order.seller)

      result = ApproveContestation.call(order: order, actor: order.seller)

      assert result.success?
      assert_equal "refunded", result.order.reload.status
      assert_equal "reversed", result.order.seller_receivable.reload.status
      assert_equal 200_00, buyer_wallet.reload.current_balance_cents
      assert_equal 0, seller_wallet.reload.current_balance_cents
      assert_equal 1, buyer_wallet.wallet_transactions.where(transaction_type: :refund, reference_type: "order_contest_resolution", reference_id: order.id).count
      assert_equal 1, seller_wallet.wallet_transactions.where(transaction_type: :debit, reference_type: "order_contest_resolution", reference_id: order.id).count
    end

    test "approve contestation is idempotent after refund" do
      order = create_contested_order

      first = ApproveContestation.call(order: order, actor: order.seller)
      second = ApproveContestation.call(order: order.reload, actor: order.seller)

      assert first.success?
      assert second.success?
      assert_equal first.buyer_refund_transaction.id, second.buyer_refund_transaction.id
      assert_equal first.seller_reversal_transaction.id, second.seller_reversal_transaction.id
    end

    test "fails closed when seller has insufficient funds to reverse credited amount" do
      order = create_contested_order
      seller_wallet = Wallet.find_by!(user: order.seller)
      spend = Wallets::Operations::ApplyMovement.call(
        wallet: seller_wallet,
        transaction_type: :debit,
        trusted_amount_cents: order.subtotal_cents,
        reference_type: "manual_spend",
        reference_id: "spend-#{order.id}",
        operation_key: "manual-spend:#{order.id}",
        metadata: { "source" => "test_spend", "reason" => "drain_wallet" }
      )
      raise "spend failed" unless spend.success?

      result = ApproveContestation.call(order: order, actor: order.seller)

      assert_not result.success?
      assert_equal :insufficient_funds, result.error_code
      assert_equal "contested", order.reload.status
      assert_equal 0, seller_wallet.reload.wallet_transactions.where(transaction_type: :debit, reference_type: "order_contest_resolution", reference_id: order.id).count
      assert_equal 0, Wallet.find_by!(user: order.user).wallet_transactions.where(transaction_type: :refund, reference_type: "order_contest_resolution", reference_id: order.id).count
    end
  end
end
