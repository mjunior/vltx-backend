class CreateOrderItems < ActiveRecord::Migration[8.0]
  def change
    create_table :order_items, id: :uuid do |t|
      t.references :order, null: false, type: :uuid, foreign_key: true
      t.references :product, null: false, type: :uuid, foreign_key: true
      t.references :seller, null: false, type: :uuid, foreign_key: { to_table: :users }
      t.string :product_title, null: false
      t.integer :quantity, null: false
      t.bigint :unit_price_cents, null: false
      t.bigint :line_subtotal_cents, null: false

      t.timestamps
    end

    add_index :order_items, [:order_id, :product_id], unique: true, name: "idx_order_items_order_product_unique"
    add_index :order_items, [:seller_id, :created_at, :id], name: "idx_order_items_seller_timeline"

    add_check_constraint :order_items, "quantity > 0", name: "order_items_quantity_positive"
    add_check_constraint :order_items, "unit_price_cents > 0", name: "order_items_unit_price_positive"
    add_check_constraint :order_items, "line_subtotal_cents > 0", name: "order_items_line_subtotal_positive"
    add_check_constraint :order_items,
                         "line_subtotal_cents = quantity * unit_price_cents",
                         name: "order_items_line_subtotal_matches_quantity"
  end
end
