class AddWalletRefundDedupUniqueIndex < ActiveRecord::Migration[8.0]
  INDEX_NAME = "idx_wallet_transactions_refund_reference_unique".freeze

  def change
    add_index :wallet_transactions,
              [:wallet_id, :reference_type, :reference_id],
              unique: true,
              where: "transaction_type = 'refund'",
              name: INDEX_NAME
  end
end
