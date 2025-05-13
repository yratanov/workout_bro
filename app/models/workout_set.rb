# == Schema Information
#
# Table name: workout_sets
#
#  id          :integer          not null, primary key
#  ended_at    :datetime
#  started_at  :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  exercise_id :integer          not null
#  workout_id  :integer          not null
#
# Indexes
#
#  index_workout_sets_on_exercise_id  (exercise_id)
#  index_workout_sets_on_workout_id   (workout_id)
#
# Foreign Keys
#
#  exercise_id  (exercise_id => exercises.id)
#  workout_id   (workout_id => workouts.id)
#

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
