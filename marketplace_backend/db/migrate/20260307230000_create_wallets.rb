class CreateWallets < ActiveRecord::Migration[8.0]
  def change
    create_table :wallets, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true, index: { unique: true }
      t.bigint :current_balance_cents, null: false, default: 0

      t.timestamps
    end

    add_check_constraint :wallets, "current_balance_cents >= 0", name: "wallets_current_balance_non_negative"
  end
end
