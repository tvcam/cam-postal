class CreateCapsuleHearts < ActiveRecord::Migration[8.1]
  def change
    create_table :capsule_hearts do |t|
      t.references :time_capsule, null: false, foreign_key: true
      t.string :ip_hash, null: false

      t.timestamps
    end

    add_index :capsule_hearts, [ :time_capsule_id, :ip_hash ], unique: true
  end
end
