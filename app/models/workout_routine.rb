class WorkoutRoutine < ApplicationRecord
  has_many :workout_routine_days, dependent: :destroy
  belongs_to :user
end
