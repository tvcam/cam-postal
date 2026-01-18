class CreateApiAccessLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :api_access_logs do |t|
      t.string :ip_address
      t.string :user_agent
      t.string :endpoint

      t.timestamps
    end

    add_index :api_access_logs, :created_at
    add_index :api_access_logs, :ip_address
  end
end
