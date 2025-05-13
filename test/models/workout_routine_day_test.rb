# == Schema Information
#
# Table name: workout_routine_days
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

require "test_helper"

class WorkoutRoutineDayTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
