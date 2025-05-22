class AddIndexesToSystemLogs < ActiveRecord::Migration[8.0]
  def change
    unless index_exists?(:system_logs, :level)
      add_index :system_logs, :level
    end
    
    unless index_exists?(:system_logs, :created_at)
      add_index :system_logs, :created_at
    end
  end
end
