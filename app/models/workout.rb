class Workout < ApplicationRecord
  has_many :workout_sets, dependent: :destroy
  has_many :exercises, through: :workout_sets
  belongs_to :workout_routine_day, optional: true
  belongs_to :user
  
  def ended?
    ended_at.present?
  end
end
