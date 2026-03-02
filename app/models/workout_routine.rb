# == Schema Information
#
# Table name: workout_routines
# Database name: primary
#
#  id                  :integer          not null, primary key
#  ai_generation_error :string
#  ai_status           :integer
#  name                :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  user_id             :integer          not null
#
# Indexes
#
#  index_workout_routines_on_user_id  (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#

class WorkoutRoutine < ApplicationRecord
  has_many :workout_routine_days, dependent: :destroy
  belongs_to :user

  enum :ai_status,
       { pending: 0, in_progress: 1, ai_completed: 2, failed: 3 },
       prefix: :ai

  def ai_generating?
    ai_pending? || ai_in_progress?
  end
end
