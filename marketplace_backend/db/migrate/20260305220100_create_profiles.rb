class CreateProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :full_name
      t.string :photo_url

      t.timestamps
    end
  end
end
