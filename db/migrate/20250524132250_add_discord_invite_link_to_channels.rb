class AddDiscordInviteLinkToChannels < ActiveRecord::Migration[8.0]
  def change
    add_column :channels, :discord_invite_link, :string
  end
end
