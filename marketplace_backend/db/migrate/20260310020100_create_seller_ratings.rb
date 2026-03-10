class CreateSellerRatings < ActiveRecord::Migration[8.0]
  def change
    create_table :seller_ratings, id: :uuid do |t|
      t.references :order, null: false, foreign_key: true, type: :uuid
      t.references :order_item, null: false, foreign_key: true, type: :uuid
      t.references :buyer, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :seller, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.integer :score, null: false
      t.text :comment, null: false

      t.timestamps
    end

    add_index :seller_ratings, :order_item_id, unique: true, name: "idx_seller_ratings_order_item_unique"
    add_index :seller_ratings, [:seller_id, :created_at, :id], name: "idx_seller_ratings_seller_timeline"
    add_check_constraint :seller_ratings, "score BETWEEN 1 AND 5", name: "seller_ratings_score_range"
  end
end
