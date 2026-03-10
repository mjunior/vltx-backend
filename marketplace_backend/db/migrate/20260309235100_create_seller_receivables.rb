class CreateSellerReceivables < ActiveRecord::Migration[8.0]
  def change
    create_table :seller_receivables, id: :uuid do |t|
      t.references :order, null: false, foreign_key: true, type: :uuid
      t.references :seller, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :buyer, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :checkout_group, null: false, foreign_key: true, type: :uuid
      t.string :status, null: false, default: "pending"
      t.bigint :amount_cents, null: false

      t.timestamps
    end

    add_index :seller_receivables, :order_id, unique: true, name: "idx_seller_receivables_order_unique"
    add_index :seller_receivables, [:seller_id, :status, :created_at, :id], name: "idx_seller_receivables_seller_status_timeline"

    add_check_constraint :seller_receivables, "status::text = ANY (ARRAY['pending'::character varying, 'reversed'::character varying, 'credited'::character varying]::text[])", name: "seller_receivables_status_allowed"
    add_check_constraint :seller_receivables, "amount_cents > 0", name: "seller_receivables_amount_positive"

    reversible do |dir|
      dir.up do
        execute <<~SQL
          INSERT INTO seller_receivables (id, order_id, seller_id, buyer_id, checkout_group_id, status, amount_cents, created_at, updated_at)
          SELECT
            gen_random_uuid(),
            orders.id,
            orders.seller_id,
            orders.user_id,
            orders.checkout_group_id,
            'pending',
            orders.subtotal_cents,
            orders.created_at,
            orders.updated_at
          FROM orders
          LEFT JOIN seller_receivables ON seller_receivables.order_id = orders.id
          WHERE seller_receivables.id IS NULL
            AND orders.checkout_group_id IS NOT NULL
        SQL
      end
    end
  end
end
