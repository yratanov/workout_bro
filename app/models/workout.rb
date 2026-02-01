# == Schema Information
#
# Table name: workouts
# Database name: primary
#
#  id                     :integer          not null, primary key
#  date                   :date
#  distance               :integer
#  ended_at               :datetime
#  notes                  :text
#  paused_at              :datetime
#  started_at             :datetime         not null
#  time_in_seconds        :integer
#  total_paused_seconds   :integer          default(0)
#  workout_type           :integer          default("strength"), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  user_id                :integer          not null
#  workout_import_id      :integer
#  workout_routine_day_id :integer
#
# Indexes
#
#  index_workouts_on_user_id                 (user_id)
#  index_workouts_on_workout_import_id       (workout_import_id)
#  index_workouts_on_workout_routine_day_id  (workout_routine_day_id)
#
# Foreign Keys
#
#  user_id                 (user_id => users.id)
#  workout_import_id       (workout_import_id => workout_imports.id) ON DELETE => nullify
#  workout_routine_day_id  (workout_routine_day_id => workout_routine_days.id) ON DELETE => nullify
#
class Workout < ApplicationRecord
  has_many :workout_sets, dependent: :destroy
  has_many :exercises, through: :workout_sets
  belongs_to :workout_routine_day, optional: true
  belongs_to :user
  belongs_to :workout_import, optional: true

  has_one :workout_routine, through: :workout_routine_day
  has_many :personal_records, dependent: :destroy

  enum :workout_type, { strength: 0, run: 1 }

  validates :workout_type, presence: true
  validates :started_at, presence: true
  validates :user, presence: true

  validates :distance, numericality: { greater_than_or_equal_to: 0 }, if: :run?
  validates :time_in_seconds,
            numericality: {
              greater_than_or_equal_to: 0
            },
            if: :run?

  validate :no_other_active_workout, on: :create

  before_validation :fill_in_time_in_seconds, if: :ended?

  def running?
    !ended?
  end

  def ended?
    ended_at.present?
  end

  def paused?
    paused_at.present?
  end

  # Pace in seconds per km
  def pace
    return nil unless distance&.positive? && time_in_seconds&.positive?

    time_in_seconds.to_f / (distance / 1000.0)
  end

  def fill_in_time_in_seconds
    if started_at.present? && ended_at.present?
      elapsed = (ended_at - started_at).to_i
      self.time_in_seconds = elapsed - (total_paused_seconds || 0)
    else
      self.time_in_seconds = nil
    end
  end

  private

  def no_other_active_workout
    return if ended_at.present? # Allow creating completed workouts (e.g., runs)

    if user && Workout.exists?(user: user, ended_at: nil)
      errors.add(:base, "You already have an active workout")
    end
  end
end
