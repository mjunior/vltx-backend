class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.references :seller, null: false, type: :uuid, foreign_key: { to_table: :users }
      t.references :source_cart, null: false, type: :uuid, foreign_key: { to_table: :carts }
      t.string :status, null: false, default: "paid"
      t.string :currency, null: false, default: "BRL"
      t.integer :total_items, null: false
      t.bigint :subtotal_cents, null: false

      t.timestamps
    end

    add_index :orders, [:source_cart_id, :seller_id], unique: true, name: "idx_orders_source_cart_seller_unique"
    add_index :orders, [:user_id, :created_at, :id], name: "idx_orders_buyer_timeline"
    add_index :orders, [:seller_id, :created_at, :id], name: "idx_orders_seller_timeline"

    add_check_constraint :orders,
                         "status IN ('paid', 'in_separation', 'confirmed', 'delivered', 'contested', 'canceled')",
                         name: "orders_status_allowed"
    add_check_constraint :orders, "total_items > 0", name: "orders_total_items_positive"
    add_check_constraint :orders, "subtotal_cents > 0", name: "orders_subtotal_positive"
  end
end
