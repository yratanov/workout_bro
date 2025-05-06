class WorkoutRoutineDay < ApplicationRecord
  belongs_to :workout_routine
  has_many :workout_routine_day_exercises, dependent: :destroy
  has_many :exercises, through: :workout_routine_day_exercises
end
