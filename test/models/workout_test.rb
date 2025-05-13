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
require "test_helper"

class WorkoutTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
