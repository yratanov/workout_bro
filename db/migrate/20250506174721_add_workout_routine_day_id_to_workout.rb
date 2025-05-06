class AddWorkoutRoutineDayIdToWorkout < ActiveRecord::Migration[8.0]
  def change
    add_reference :workouts, :workout_routine_day, foreign_key: true
  end
end
