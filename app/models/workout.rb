class Workout < ApplicationRecord
  has_many :workout_sets, dependent: :destroy
  has_many :exercises, through: :workout_sets
  belongs_to :workout_routine_day, optional: true
  belongs_to :user
  
  has_one :workout_routine, through: :workout_routine_day
  
  def ended?
    ended_at.present?
  end
end
