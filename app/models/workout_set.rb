# == Schema Information
#
# Table name: workout_sets
#
#  id                   :integer          not null, primary key
#  ended_at             :datetime
#  paused_at            :datetime
#  started_at           :datetime
#  total_paused_seconds :integer          default(0)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  exercise_id          :integer          not null
#  workout_id           :integer          not null
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

  def paused?
    paused_at.present?
  end

  def previous_workout_set
    @previous_workout_set ||= workout.user.workout_sets
      .where(exercise:)
      .where.not(id:)
      .where.not(ended_at: nil)
      .order(created_at: :desc)
      .first
  end

  def default_rep_values
    current_rep_index = workout_reps.count
    prev_rep = previous_workout_set&.workout_reps&.order(:created_at)&.[](current_rep_index)

    if prev_rep
      { weight: prev_rep.weight, reps: prev_rep.reps, band: prev_rep.band }
    else
      { weight: 10, reps: 10, band: nil }
    end
  end
end
