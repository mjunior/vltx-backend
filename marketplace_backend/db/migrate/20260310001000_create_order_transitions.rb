class CreateOrderTransitions < ActiveRecord::Migration[8.0]
  def change
    create_table :order_transitions, id: :uuid do |t|
      t.references :order, null: false, foreign_key: true, type: :uuid
      t.references :actor, null: true, foreign_key: { to_table: :users }, type: :uuid
      t.string :actor_role, null: false
      t.string :action, null: false
      t.string :from_status
      t.string :to_status, null: false
      t.integer :position, null: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :order_transitions, [:order_id, :position], unique: true, name: "idx_order_transitions_order_position_unique"
    add_index :order_transitions, [:order_id, :created_at, :id], name: "idx_order_transitions_order_timeline"

    add_check_constraint :order_transitions,
                         "actor_role::text = ANY (ARRAY['buyer'::character varying, 'seller'::character varying, 'system'::character varying]::text[])",
                         name: "order_transitions_actor_role_allowed"
    add_check_constraint :order_transitions,
                         "to_status::text = ANY (ARRAY['paid'::character varying, 'in_separation'::character varying, 'confirmed'::character varying, 'delivered'::character varying, 'contested'::character varying, 'canceled'::character varying]::text[])",
                         name: "order_transitions_to_status_allowed"
    add_check_constraint :order_transitions,
                         "(from_status IS NULL) OR from_status::text = ANY (ARRAY['paid'::character varying, 'in_separation'::character varying, 'confirmed'::character varying, 'delivered'::character varying, 'contested'::character varying, 'canceled'::character varying]::text[])",
                         name: "order_transitions_from_status_allowed"

    reversible do |dir|
      dir.up do
        execute <<~SQL
          INSERT INTO order_transitions (id, order_id, actor_id, actor_role, action, from_status, to_status, position, metadata, created_at, updated_at)
          SELECT
            gen_random_uuid(),
            orders.id,
            NULL,
            'system',
            'backfill',
            NULL,
            orders.status,
            1,
            '{}'::jsonb,
            orders.created_at,
            orders.updated_at
          FROM orders
          LEFT JOIN order_transitions ON order_transitions.order_id = orders.id
          WHERE order_transitions.id IS NULL
        SQL
      end
    end
  end
end
