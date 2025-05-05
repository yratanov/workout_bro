class Workout < ApplicationRecord
  has_many :workout_sets, dependent: :destroy
  
  def ended?
    ended_at.present?
  end
end
