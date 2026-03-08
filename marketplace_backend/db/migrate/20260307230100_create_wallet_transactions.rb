class CreateWalletTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :wallet_transactions, id: :uuid do |t|
      t.references :wallet, null: false, type: :uuid, foreign_key: true
      t.string :transaction_type, null: false
      t.bigint :amount_cents, null: false
      t.bigint :balance_after_cents, null: false
      t.string :reference_type, null: false
      t.string :reference_id, null: false
      t.string :operation_key, null: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :wallet_transactions, [:wallet_id, :created_at, :id], name: "idx_wallet_transactions_wallet_timeline"
    add_index :wallet_transactions, [:wallet_id, :operation_key], unique: true, name: "idx_wallet_transactions_wallet_operation_key_unique"

    add_check_constraint :wallet_transactions,
                         "transaction_type IN ('credit', 'debit', 'refund')",
                         name: "wallet_transactions_type_allowed"
    add_check_constraint :wallet_transactions, "amount_cents > 0", name: "wallet_transactions_amount_positive"
    add_check_constraint :wallet_transactions,
                         "balance_after_cents >= 0",
                         name: "wallet_transactions_balance_after_non_negative"
  end
end
