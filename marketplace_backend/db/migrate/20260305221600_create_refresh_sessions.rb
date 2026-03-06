class CreateRefreshSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :refresh_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :refresh_jti, null: false
      t.string :refresh_token_hash, null: false
      t.datetime :expires_at, null: false
      t.datetime :revoked_at
      t.datetime :rotated_at

      t.timestamps
    end

    add_index :refresh_sessions, :refresh_jti, unique: true
    add_index :refresh_sessions, [:user_id, :revoked_at]
    add_index :refresh_sessions, :expires_at
  end
end
