class WorkoutSet < ApplicationRecord
  belongs_to :workout
  belongs_to :exercise

  has_many :workout_reps, dependent: :destroy

  def running?
    !ended?
  end

  def ended?
    ended_at.present?
  end
end
