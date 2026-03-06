class AddProductsStockQuantityNonNegativeCheck < ActiveRecord::Migration[8.0]
  CONSTRAINT_NAME = "products_stock_quantity_non_negative"

  def up
    add_check_constraint :products,
                         "stock_quantity >= 0",
                         name: CONSTRAINT_NAME,
                         validate: true
  end

  def down
    remove_check_constraint :products, name: CONSTRAINT_NAME
  end
end
