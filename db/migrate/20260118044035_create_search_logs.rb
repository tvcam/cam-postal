class CreateSearchLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :search_logs do |t|
      t.string :query, null: false
      t.string :ip_address
      t.string :user_agent
      t.integer :results_count, default: 0

      t.timestamps
    end

    add_index :search_logs, :query
    add_index :search_logs, :created_at
  end
end
