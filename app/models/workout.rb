# == Schema Information
#
# Table name: workouts
#
#  id                     :integer          not null, primary key
#  date                   :date
#  distance               :integer
#  ended_at               :datetime
#  started_at             :datetime
#  time_in_seconds        :integer
#  workout_type           :integer          default("strength"), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  user_id                :integer
#  workout_routine_day_id :integer
#
# Indexes
#
#  index_workouts_on_user_id                 (user_id)
#  index_workouts_on_workout_routine_day_id  (workout_routine_day_id)
#
# Foreign Keys
#
#  user_id                 (user_id => users.id)
#  workout_routine_day_id  (workout_routine_day_id => workout_routine_days.id)
#
class Workout < ApplicationRecord
  has_many :workout_sets, dependent: :destroy
  has_many :exercises, through: :workout_sets
  belongs_to :workout_routine_day, optional: true
  belongs_to :user
  
  has_one :workout_routine, through: :workout_routine_day

  enum :workout_type, {
    strength: 0,
    run: 1,
  }

  validates :workout_type, presence: true
  validates :started_at, presence: true
  validates :workout_routine_day, presence: true, if: :strength?
  validates :user, presence: true

  validates :distance, numericality: { greater_than_or_equal_to: 0 }, if: :run?
  validates :time_in_seconds, numericality: { greater_than_or_equal_to: 0 }, if: :run?

  before_save :fill_in_time_in_seconds, if: :ended?
  
  def running?
    !ended?
  end
  
  def ended?
    ended_at.present?
  end

  def fill_in_time_in_seconds
    if started_at.present? && ended_at.present?
      self.time_in_seconds = (ended_at - started_at).to_i
    else
      self.time_in_seconds = nil
    end
  end
end
