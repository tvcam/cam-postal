class CreateSiteStats < ActiveRecord::Migration[8.1]
  def change
    create_table :site_stats do |t|
      t.string :name
      t.integer :value

      t.timestamps
    end
    add_index :site_stats, :name, unique: true
  end
end
