# == Schema Information
#
# Table name: personal_records
# Database name: primary
#
#  id             :integer          not null, primary key
#  achieved_on    :date             not null
#  band           :string
#  pr_type        :integer          default("max_weight"), not null
#  reps           :integer          not null
#  volume         :float
#  weight         :float
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  exercise_id    :integer          not null
#  user_id        :integer          not null
#  workout_id     :integer          not null
#  workout_rep_id :integer          not null
#
# Indexes
#
#  index_personal_records_on_exercise_id     (exercise_id)
#  index_personal_records_on_user_id         (user_id)
#  index_personal_records_on_workout_id      (workout_id)
#  index_personal_records_on_workout_rep_id  (workout_rep_id)
#  index_prs_on_user_exercise_type_band      (user_id,exercise_id,pr_type,band)
#
# Foreign Keys
#
#  exercise_id     (exercise_id => exercises.id) ON DELETE => cascade
#  user_id         (user_id => users.id)
#  workout_id      (workout_id => workouts.id) ON DELETE => cascade
#  workout_rep_id  (workout_rep_id => workout_reps.id) ON DELETE => cascade
#
class PersonalRecord < ApplicationRecord
  belongs_to :user
  belongs_to :exercise
  belongs_to :workout_rep
  belongs_to :workout

  enum :pr_type, { max_weight: 0, max_volume: 1, max_reps: 2 }

  validates :pr_type, presence: true
  validates :reps,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than: 0
            }
  validates :achieved_on, presence: true
  validates :weight,
            numericality: {
              greater_than_or_equal_to: 0
            },
            allow_nil: true
  validates :volume, numericality: { greater_than: 0 }, allow_nil: true
  validates :band, inclusion: { in: [nil, *WorkoutRep::BANDS] }

  scope :recent_first, -> { order(achieved_on: :desc, created_at: :desc) }
  scope :timeline, -> { recent_first.includes(:exercise, :workout) }
end
