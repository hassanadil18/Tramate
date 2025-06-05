class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.string :name
      t.decimal :price, precision: 10, scale: 2, default: 0.0
      t.text :description
      t.integer :trade_limit
      t.references :user, null: true, foreign_key: true
      t.string :status

      t.timestamps
    end
  end
end
