class CreateGeocodeCaches < ActiveRecord::Migration[8.1]
  def change
    create_table :geocode_caches do |t|
      t.decimal :lat, precision: 7, scale: 3, null: false
      t.decimal :lng, precision: 7, scale: 3, null: false
      t.string :postal_code
      t.string :area
      t.string :display_name

      t.timestamps
    end

    add_index :geocode_caches, [:lat, :lng], unique: true
  end
end
