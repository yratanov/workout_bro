class AddWithWeightsAndWithBandToExercises < ActiveRecord::Migration[8.0]
  def change
    add_column :exercises, :with_weights, :boolean, default: true, null: false
    add_column :exercises, :with_band, :boolean, default: false, null: false
  end
end
