class CreateCartItems < ActiveRecord::Migration[8.0]
  def change
    create_table :cart_items, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :cart, null: false, foreign_key: true, type: :uuid
      t.references :product, null: false, foreign_key: true, type: :uuid
      t.integer :quantity, null: false

      t.timestamps
    end

    add_index :cart_items, [:cart_id, :product_id], unique: true
    add_check_constraint :cart_items, "quantity > 0", name: "cart_items_quantity_positive"
  end
end
