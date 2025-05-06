class WorkoutRoutineDayExercise < ApplicationRecord
  belongs_to :workout_routine_day
  belongs_to :exercise
end
