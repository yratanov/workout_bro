# == Schema Information
#
# Table name: workout_routine_day_exercises
# Database name: primary
#
#  id                     :integer          not null, primary key
#  position               :integer
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
#  superset_id             (superset_id => supersets.id) ON DELETE => cascade
#  workout_routine_day_id  (workout_routine_day_id => workout_routine_days.id)
#

class WorkoutRoutineDayExercise < ApplicationRecord
  belongs_to :workout_routine_day
  belongs_to :exercise, optional: true
  belongs_to :superset, optional: true

  validate :exercise_or_superset_required

  def display_name
    superset? ? superset.display_name : exercise.name
  end

  def superset?
    superset_id.present?
  end

  private

  def exercise_or_superset_required
    if exercise_id.blank? && superset_id.blank?
      errors.add(:base, :exercise_or_superset_required)
    elsif exercise_id.present? && superset_id.present?
      errors.add(:base, :exercise_xor_superset)
    end
  end
end
