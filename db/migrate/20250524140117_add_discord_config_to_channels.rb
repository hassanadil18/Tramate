class AddDiscordConfigToChannels < ActiveRecord::Migration[8.0]
  def change
    add_column :channels, :discord_guild_id, :string
    add_column :channels, :discord_webhook_url, :string
    add_column :channels, :discord_bot_permissions, :text
    
    # Add indexes for performance
    add_index :channels, :discord_guild_id
  end
end
