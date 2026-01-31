# == Schema Information
#
# Table name: personal_records
# Database name: primary
#
#  id             :integer          not null, primary key
#  achieved_on    :date             not null
#  band           :string
#  distance       :integer
#  pace           :float
#  pr_type        :integer          default("max_weight"), not null
#  reps           :integer
#  volume         :float
#  weight         :float
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  exercise_id    :integer
#  user_id        :integer          not null
#  workout_id     :integer          not null
#  workout_rep_id :integer
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
  belongs_to :exercise, optional: true
  belongs_to :workout_rep, optional: true
  belongs_to :workout

  enum :pr_type,
       {
         max_weight: 0,
         max_volume: 1,
         max_reps: 2,
         longest_distance: 3,
         fastest_pace: 4
       }

  STRENGTH_PR_TYPES = %w[max_weight max_volume max_reps].freeze
  RUN_PR_TYPES = %w[longest_distance fastest_pace].freeze

  validates :pr_type, presence: true
  validates :achieved_on, presence: true

  # Strength PR validations
  validates :exercise, presence: true, if: :strength_pr?
  validates :workout_rep, presence: true, if: :strength_pr?
  validates :reps,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than: 0
            },
            if: :strength_pr?
  validates :weight,
            numericality: {
              greater_than_or_equal_to: 0
            },
            allow_nil: true
  validates :volume, numericality: { greater_than: 0 }, allow_nil: true
  validates :band, inclusion: { in: [nil, *WorkoutRep::BANDS] }

  # Run PR validations
  validates :distance,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than: 0
            },
            if: :run_pr?
  validates :pace,
            presence: true,
            numericality: {
              greater_than: 0
            },
            if: -> { fastest_pace? }

  scope :recent_first, -> { order(achieved_on: :desc, created_at: :desc) }
  scope :timeline, -> { recent_first.includes(:exercise, :workout) }
  scope :strength, -> { where(pr_type: STRENGTH_PR_TYPES) }
  scope :runs, -> { where(pr_type: RUN_PR_TYPES) }

  def strength_pr?
    STRENGTH_PR_TYPES.include?(pr_type)
  end

  def run_pr?
    RUN_PR_TYPES.include?(pr_type)
  end
end
