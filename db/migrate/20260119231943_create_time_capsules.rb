class CreateTimeCapsules < ActiveRecord::Migration[8.1]
  def change
    create_table :time_capsules do |t|
      t.references :postal_code, null: false, foreign_key: true
      t.text :message, null: false
      t.string :mood, default: "hopeful"
      t.string :nickname
      t.string :ip_hash
      t.datetime :visible_at, default: -> { "CURRENT_TIMESTAMP" }
      t.integer :hearts_count, default: 0
      t.boolean :approved, default: true
      t.boolean :flagged, default: false

      t.timestamps
    end

    add_index :time_capsules, :visible_at
    add_index :time_capsules, [ :postal_code_id, :visible_at ]
  end
end
