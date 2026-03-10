class CreateCheckoutGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :checkout_groups, id: :uuid do |t|
      t.references :buyer, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :source_cart, null: false, foreign_key: { to_table: :carts }, type: :uuid
      t.string :currency, null: false, default: "BRL"
      t.integer :total_items, null: false
      t.bigint :subtotal_cents, null: false

      t.timestamps
    end

    add_index :checkout_groups, :source_cart_id, unique: true, name: "idx_checkout_groups_source_cart_unique"
    add_index :checkout_groups, [:buyer_id, :created_at, :id], name: "idx_checkout_groups_buyer_timeline"

    add_check_constraint :checkout_groups, "total_items > 0", name: "checkout_groups_total_items_positive"
    add_check_constraint :checkout_groups, "subtotal_cents > 0", name: "checkout_groups_subtotal_positive"

    add_reference :orders, :checkout_group, foreign_key: true, type: :uuid

    reversible do |dir|
      dir.up do
        execute <<~SQL
          INSERT INTO checkout_groups (id, buyer_id, source_cart_id, currency, total_items, subtotal_cents, created_at, updated_at)
          SELECT
            gen_random_uuid(),
            orders.user_id,
            orders.source_cart_id,
            MIN(orders.currency),
            SUM(orders.total_items),
            SUM(orders.subtotal_cents),
            MIN(orders.created_at),
            MAX(orders.updated_at)
          FROM orders
          GROUP BY orders.user_id, orders.source_cart_id
        SQL

        execute <<~SQL
          UPDATE orders
          SET checkout_group_id = checkout_groups.id
          FROM checkout_groups
          WHERE checkout_groups.buyer_id = orders.user_id
            AND checkout_groups.source_cart_id = orders.source_cart_id
        SQL

        change_column_null :orders, :checkout_group_id, false
      end
    end
  end
end
