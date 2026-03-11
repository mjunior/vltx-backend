class AddPasswordResetNonceToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :password_reset_nonce, :string
  end
end
