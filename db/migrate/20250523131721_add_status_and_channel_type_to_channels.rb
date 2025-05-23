class AddStatusAndChannelTypeToChannels < ActiveRecord::Migration[8.0]
  def change
    add_column :channels, :status, :string, default: 'active'
    add_column :channels, :channel_type, :string, default: 'discord'
    add_column :channels, :logo_url, :string
    
    # Add indexes for better performance
    add_index :channels, :status
    add_index :channels, :channel_type
  end
end
