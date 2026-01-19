class CreateThirdPartyCredentials < ActiveRecord::Migration[8.0]
  def change
    create_table :third_party_credentials do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :username
      t.string :encrypted_password

      t.timestamps
    end

    add_index :third_party_credentials, [ :user_id, :provider ], unique: true
  end
end
