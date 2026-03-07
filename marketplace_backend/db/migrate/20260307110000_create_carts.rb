class CreateCarts < ActiveRecord::Migration[8.0]
  def change
    create_table :carts, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    add_index :carts, [:user_id, :status]
  end
end
