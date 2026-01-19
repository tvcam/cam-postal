class CreateFeedbacks < ActiveRecord::Migration[8.1]
  def change
    create_table :feedbacks do |t|
      t.string :name
      t.string :email
      t.text :message
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end
  end
end
