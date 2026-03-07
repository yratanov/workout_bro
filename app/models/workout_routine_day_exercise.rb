# == Schema Information
#
# Table name: workout_routine_day_exercises
# Database name: primary
#
#  id                     :integer          not null, primary key
#  comment                :text
#  max_rest               :integer
#  min_rest               :integer
#  position               :integer
#  reps                   :string
#  sets                   :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  exercise_id            :integer
#  superset_id            :integer
#  workout_routine_day_id :integer          not null
#
# Indexes
#
#  index_workout_routine_day_exercises_on_exercise_id             (exercise_id)
#  index_workout_routine_day_exercises_on_superset_id             (superset_id)
#  index_workout_routine_day_exercises_on_workout_routine_day_id  (workout_routine_day_id)
#
# Foreign Keys
#
#  exercise_id             (exercise_id => exercises.id)
#  superset_id             (superset_id => supersets.id)
#  workout_routine_day_id  (workout_routine_day_id => workout_routine_days.id)
#

class WorkoutRoutineDayExercise < ApplicationRecord
  belongs_to :workout_routine_day
  belongs_to :exercise, optional: true
  belongs_to :superset, optional: true

  validates :min_rest, numericality: { greater_than: 0 }, allow_nil: true
  validates :max_rest, numericality: { greater_than: 0 }, allow_nil: true
  validate :exercise_or_superset_required
  validate :min_rest_not_greater_than_max_rest

  def display_name
    superset? ? superset.display_name : exercise.name
  end

  def superset?
    superset_id.present?
  end

  private

  def min_rest_not_greater_than_max_rest
    return unless min_rest.present? && max_rest.present?

    if min_rest > max_rest
      errors.add(:min_rest, :less_than_or_equal_to, count: max_rest)
    end
  end

  def exercise_or_superset_required
    if exercise_id.blank? && superset_id.blank?
      errors.add(:base, :exercise_or_superset_required)
    elsif exercise_id.present? && superset_id.present?
      errors.add(:base, :exercise_xor_superset)
    end
  end
end
