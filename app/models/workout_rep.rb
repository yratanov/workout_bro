# == Schema Information
#
# Table name: workout_reps
#
#  id             :integer          not null, primary key
#  reps           :integer
#  weight         :float
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  workout_set_id :integer          not null
#
# Indexes
#
#  index_workout_reps_on_workout_set_id  (workout_set_id)
#
# Foreign Keys
#
#  workout_set_id  (workout_set_id => workout_sets.id)
#

class WorkoutRep < ApplicationRecord
  belongs_to :workout_set

  validates :reps, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :weight, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :workout_set_id, presence: true
end
