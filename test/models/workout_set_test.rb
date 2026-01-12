# == Schema Information
#
# Table name: workout_sets
#
#  id                   :integer          not null, primary key
#  ended_at             :datetime
#  paused_at            :datetime
#  started_at           :datetime
#  total_paused_seconds :integer          default(0)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  exercise_id          :integer          not null
#  workout_id           :integer          not null
#
# Indexes
#
#  index_workout_sets_on_exercise_id  (exercise_id)
#  index_workout_sets_on_workout_id   (workout_id)
#
# Foreign Keys
#
#  exercise_id  (exercise_id => exercises.id)
#  workout_id   (workout_id => workouts.id)
#

require "test_helper"

class WorkoutSetTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
