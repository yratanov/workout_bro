# == Schema Information
#
# Table name: workout_sets
# Database name: primary
#
#  id                   :integer          not null, primary key
#  ended_at             :datetime
#  notes                :text
#  paused_at            :datetime
#  started_at           :datetime
#  superset_group       :integer
#  total_paused_seconds :integer          default(0)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  exercise_id          :integer          not null
#  superset_id          :integer
#  workout_id           :integer          not null
#
# Indexes
#
#  index_workout_sets_on_exercise_id                    (exercise_id)
#  index_workout_sets_on_superset_id                    (superset_id)
#  index_workout_sets_on_workout_id_and_superset_group  (workout_id,superset_group)
#
# Foreign Keys
#
#  exercise_id  (exercise_id => exercises.id) ON DELETE => restrict
#  superset_id  (superset_id => supersets.id) ON DELETE => nullify
#  workout_id   (workout_id => workouts.id)
#

class WorkoutSet < ApplicationRecord
  belongs_to :workout
  belongs_to :exercise
  belongs_to :superset, optional: true

  has_many :workout_reps, dependent: :destroy

  scope :in_superset_group, ->(group) { where(superset_group: group) }

  def running?
    !ended?
  end

  def ended?
    ended_at.present?
  end

  def paused?
    paused_at.present?
  end

  def in_superset?
    superset_id.present? && superset_group.present?
  end

  def superset_sibling_sets
    return WorkoutSet.none unless in_superset?
    workout.workout_sets.in_superset_group(superset_group).where.not(id: id)
  end

  def all_superset_sets
    return WorkoutSet.none unless in_superset?
    workout.workout_sets.in_superset_group(superset_group)
  end

  def previous_workout_set
    @previous_workout_set ||=
      workout
        .user
        .workout_sets
        .where(exercise:)
        .where.not(id:)
        .where.not(ended_at: nil)
        .order(created_at: :desc)
        .first
  end

  def default_rep_values
    current_rep_index = workout_reps.count

    # 1. Try to get values from the same rep index of previous workout's same exercise
    prev_workout_rep =
      previous_workout_set
        &.workout_reps
        &.order(:created_at)
        &.[](current_rep_index)
    return values_from_rep(prev_workout_rep) if prev_workout_rep

    # 2. Fall back to the last rep in the current set
    last_rep = workout_reps.order(:created_at).last
    return values_from_rep(last_rep) if last_rep

    # 3. Default values
    { reps: 10, weight: 10, band: nil }
  end

  private

  def values_from_rep(rep)
    { reps: rep.reps, weight: rep.weight, band: rep.band }
  end
end
