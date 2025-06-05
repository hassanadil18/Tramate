class AddSubscriptionInfoToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :subscription_id, :integer
    add_column :users, :trades_count, :integer
    add_column :users, :subscription_start_date, :datetime
    add_column :users, :subscription_end_date, :datetime
  end
end
