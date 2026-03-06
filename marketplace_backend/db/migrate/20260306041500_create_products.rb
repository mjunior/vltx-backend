class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.string :title, null: false
      t.text :description, null: false
      t.decimal :price, precision: 9, scale: 2, null: false
      t.integer :stock_quantity, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :products, :active
    add_index :products, :created_at
  end
end
