class CreateProductRatings < ActiveRecord::Migration[8.0]
  def change
    create_table :product_ratings, id: :uuid do |t|
      t.references :order, null: false, foreign_key: true, type: :uuid
      t.references :order_item, null: false, foreign_key: true, type: :uuid
      t.references :buyer, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :product, null: false, foreign_key: true, type: :uuid
      t.integer :score, null: false
      t.text :comment, null: false

      t.timestamps
    end

    add_index :product_ratings, :order_item_id, unique: true, name: "idx_product_ratings_order_item_unique"
    add_index :product_ratings, [:product_id, :created_at, :id], name: "idx_product_ratings_product_timeline"
    add_check_constraint :product_ratings, "score BETWEEN 1 AND 5", name: "product_ratings_score_range"
  end
end
