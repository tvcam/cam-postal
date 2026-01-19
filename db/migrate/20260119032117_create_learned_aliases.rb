class CreateLearnedAliases < ActiveRecord::Migration[8.1]
  def change
    create_table :learned_aliases do |t|
      t.string :search_term, null: false
      t.string :postal_code, null: false
      t.integer :click_count, default: 0, null: false
      t.integer :search_count, default: 0, null: false
      t.integer :unique_ips, default: 0, null: false
      t.boolean :promoted, default: false, null: false
      t.datetime :last_clicked_at

      t.timestamps
    end

    add_index :learned_aliases, [ :search_term, :postal_code ], unique: true
    add_index :learned_aliases, :search_term
    add_index :learned_aliases, :promoted
    add_index :learned_aliases, :click_count
    add_index :learned_aliases, :last_clicked_at
  end
end
