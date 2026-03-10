class AddVerificationStatusToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :verification_status, :string, null: false, default: "unverified"
    add_index :users, :verification_status
  end
end
