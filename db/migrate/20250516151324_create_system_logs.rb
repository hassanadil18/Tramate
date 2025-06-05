class CreateSystemLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :system_logs do |t|
      t.string :level, null: false
      t.text :message, null: false
      t.jsonb :context
      t.timestamps
    end
    
    add_index :system_logs, :level
    add_index :system_logs, :created_at
  end
end 