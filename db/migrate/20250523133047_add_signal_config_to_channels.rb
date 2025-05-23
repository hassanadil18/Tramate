class AddSignalConfigToChannels < ActiveRecord::Migration[8.0]
  def change
    add_column :channels, :signal_format, :string, default: 'standard'
    add_column :channels, :signal_template, :text
    add_column :channels, :webhook_url, :string
    add_column :channels, :api_key, :string
    
    # Add index for better query performance
    add_index :channels, :signal_format
  end
end
