class AddUniqueActiveCartIndex < ActiveRecord::Migration[8.0]
  def change
    add_index :carts,
              :user_id,
              unique: true,
              where: "status = 'active'",
              name: "index_carts_on_user_id_active_unique"
  end
end
