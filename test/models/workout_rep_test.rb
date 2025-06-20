# == Schema Information
#
# Table name: workout_reps
#
#  id             :integer          not null, primary key
#  band           :string
#  reps           :integer
#  weight         :float
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  workout_set_id :integer          not null
#
# Indexes
#
#  index_workout_reps_on_workout_set_id  (workout_set_id)
#
# Foreign Keys
#
#  workout_set_id  (workout_set_id => workout_sets.id)
#

require "test_helper"

class WorkoutRepTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
