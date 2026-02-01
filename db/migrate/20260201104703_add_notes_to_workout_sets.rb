class AddNotesToWorkoutSets < ActiveRecord::Migration[8.1]
  def change
    add_column :workout_sets, :notes, :text
  end
end
