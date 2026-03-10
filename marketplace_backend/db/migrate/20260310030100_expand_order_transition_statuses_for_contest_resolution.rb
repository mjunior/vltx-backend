class ExpandOrderTransitionStatusesForContestResolution < ActiveRecord::Migration[8.0]
  def change
    remove_check_constraint :order_transitions, name: "order_transitions_to_status_allowed"
    remove_check_constraint :order_transitions, name: "order_transitions_from_status_allowed"

    add_check_constraint :order_transitions,
                         "to_status IN ('paid', 'in_separation', 'confirmed', 'delivered', 'contested', 'refunded', 'canceled')",
                         name: "order_transitions_to_status_allowed"
    add_check_constraint :order_transitions,
                         "from_status IS NULL OR from_status IN ('paid', 'in_separation', 'confirmed', 'delivered', 'contested', 'refunded', 'canceled')",
                         name: "order_transitions_from_status_allowed"
  end
end
