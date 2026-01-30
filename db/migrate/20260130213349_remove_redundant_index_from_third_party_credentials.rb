class RemoveRedundantIndexFromThirdPartyCredentials < ActiveRecord::Migration[8.1]
  def change
    # This index is redundant because index_third_party_credentials_on_user_id_and_provider covers it
    remove_index :third_party_credentials, :user_id, name: "index_third_party_credentials_on_user_id"
  end
end
