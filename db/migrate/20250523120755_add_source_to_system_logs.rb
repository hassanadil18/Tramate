class AddSourceToSystemLogs < ActiveRecord::Migration[8.0]
  def change
    add_column :system_logs, :source, :string
  end
end
