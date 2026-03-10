class ExpandOrderStatusesForContestResolution < ActiveRecord::Migration[8.0]
  def change
    remove_check_constraint :orders, name: "orders_status_allowed"
    add_check_constraint :orders,
                         "status IN ('paid', 'in_separation', 'confirmed', 'delivered', 'contested', 'refunded', 'canceled')",
                         name: "orders_status_allowed"
  end
end
