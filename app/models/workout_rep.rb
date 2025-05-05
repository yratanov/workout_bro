class WorkoutRep < ApplicationRecord
  belongs_to :workout_set

  validates :reps, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :weight, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :workout_set_id, presence: true
end
