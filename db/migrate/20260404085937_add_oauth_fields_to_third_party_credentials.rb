class AddOauthFieldsToThirdPartyCredentials < ActiveRecord::Migration[8.1]
  def change
    add_column :third_party_credentials, :access_token, :string
    add_column :third_party_credentials, :refresh_token, :string
    add_column :third_party_credentials, :token_expires_at, :datetime
  end
end
