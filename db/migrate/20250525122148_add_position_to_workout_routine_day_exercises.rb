class AddPositionToWorkoutRoutineDayExercises < ActiveRecord::Migration[8.0]
  def change
    add_column :workout_routine_day_exercises, :position, :integer

    WorkoutRoutineDay.find_each do |day|
      day.workout_routine_day_exercises.order(:created_at).each_with_index do |exercise, index|
        exercise.update(position: index + 1)
      end
    end
  end
end
