class CreateProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :profiles, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true, index: { unique: true }
      t.string :full_name
      t.string :address
      t.string :photo_url

      t.timestamps
    end
  end
end
