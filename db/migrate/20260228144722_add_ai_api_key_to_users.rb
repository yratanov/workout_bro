class AddAiApiKeyToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :ai_api_key, :string
  end
end
