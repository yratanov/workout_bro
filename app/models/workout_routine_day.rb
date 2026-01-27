# == Schema Information
#
# Table name: workout_routine_days
# Database name: primary
#
#  id                 :integer          not null, primary key
#  name               :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  workout_routine_id :integer          not null
#
# Indexes
#
#  index_workout_routine_days_on_workout_routine_id  (workout_routine_id)
#
# Foreign Keys
#
#  workout_routine_id  (workout_routine_id => workout_routines.id)
#

class WorkoutRoutineDay < ApplicationRecord
  belongs_to :workout_routine
  has_many :workout_routine_day_exercises, dependent: :destroy
  has_many :exercises, through: :workout_routine_day_exercises

  validates :name, presence: true
end
