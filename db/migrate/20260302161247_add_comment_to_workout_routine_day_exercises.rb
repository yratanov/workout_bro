class AddCommentToWorkoutRoutineDayExercises < ActiveRecord::Migration[8.1]
  def change
    add_column :workout_routine_day_exercises, :comment, :text
  end
end
