class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.text :message, null: false
      t.boolean :read, default: false
      t.string :notification_type
      t.datetime :read_at
      t.json :data

      t.timestamps
    end
    
    add_index :notifications, :read
  end
end
