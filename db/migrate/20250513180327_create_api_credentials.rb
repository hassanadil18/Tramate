class CreateApiCredentials < ActiveRecord::Migration[8.0]
  def change
    create_table :api_credentials do |t|
      t.references :user, null: false, foreign_key: true
      t.string :platform
      t.string :api_key
      t.string :api_secret
      t.string :ip_restriction
      t.string :label
      t.boolean :active

      t.timestamps
    end
  end
end
