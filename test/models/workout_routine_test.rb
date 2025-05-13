# == Schema Information
#
# Table name: workout_routines
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer
#
# Indexes
#
#  index_workout_routines_on_user_id  (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#

require "test_helper"

class WorkoutRoutineTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
