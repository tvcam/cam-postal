class CreateNluCaches < ActiveRecord::Migration[8.1]
  def change
    create_table :nlu_caches do |t|
      t.string :query_hash, null: false
      t.string :original_query, null: false
      t.json :parsed_intent, null: false
      t.integer :hit_count, default: 0, null: false

      t.timestamps
    end
    add_index :nlu_caches, :query_hash, unique: true
  end
end
