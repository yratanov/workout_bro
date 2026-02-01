class AddSupersetToWorkoutRoutineDayExercises < ActiveRecord::Migration[8.1]
  def change
    add_reference :workout_routine_day_exercises, :superset, foreign_key: { on_delete: :cascade }
    change_column_null :workout_routine_day_exercises, :exercise_id, true
  end
end
