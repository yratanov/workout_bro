class AddWorkoutImportIdToWorkouts < ActiveRecord::Migration[8.0]
  def change
    add_reference :workouts, :workout_import, foreign_key: true
  end
end
