class CreateAdminRefreshSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :admin_refresh_sessions do |t|
      t.references :admin, null: false, foreign_key: true
      t.string :refresh_jti, null: false
      t.string :refresh_token_hash, null: false
      t.datetime :expires_at, null: false
      t.datetime :revoked_at
      t.datetime :rotated_at

      t.timestamps
    end

    add_index :admin_refresh_sessions, :refresh_jti, unique: true
  end
end
