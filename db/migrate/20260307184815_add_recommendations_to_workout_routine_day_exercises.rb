class AddRecommendationsToWorkoutRoutineDayExercises < ActiveRecord::Migration[8.1]
  def change
    add_column :workout_routine_day_exercises, :sets, :string
    add_column :workout_routine_day_exercises, :reps, :string
    add_column :workout_routine_day_exercises, :min_rest, :integer
    add_column :workout_routine_day_exercises, :max_rest, :integer
  end
end
