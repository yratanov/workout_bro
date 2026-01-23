class AddWizardFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :locale, :string, default: "en"
    add_column :users, :wizard_step, :integer, default: 0
    add_column :users, :setup_completed, :boolean, default: false
  end
end
