class AddSyncEnabledToThirdPartyCredentials < ActiveRecord::Migration[8.1]
  def change
    add_column :third_party_credentials, :sync_enabled, :boolean, default: true, null: false
  end
end
