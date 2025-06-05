class AddBinanceFieldsToApiCredentials < ActiveRecord::Migration[8.0]
  def change
    add_column :api_credentials, :connection_type, :string
    add_column :api_credentials, :account_type, :string
    add_column :api_credentials, :can_trade, :boolean
    add_column :api_credentials, :can_withdraw, :boolean
    add_column :api_credentials, :validated_at, :datetime
  end
end
