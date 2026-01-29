class AddWeightSettingsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :weight_unit, :string, default: "kg", null: false
    add_column :users, :weight_min, :float, default: 2.5, null: false
    add_column :users, :weight_max, :float, default: 100, null: false
    add_column :users, :weight_step, :float, default: 2.5, null: false
  end
end
