# == Schema Information
#
# Table name: workout_reps
# Database name: primary
#
#  id             :integer          not null, primary key
#  band           :string
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

  BANDS = %w[lightest light medium heavy].freeze
  validates :reps,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than: 0
            }
  validates :weight,
            numericality: {
              greater_than_or_equal_to: 0
            },
            allow_nil: true
  validates :band, inclusion: { in: [nil, *BANDS] }
  validates :workout_set_id, presence: true
end
