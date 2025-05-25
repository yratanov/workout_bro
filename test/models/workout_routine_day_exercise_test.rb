# == Schema Information
#
# Table name: workout_routine_day_exercises
#
#  id                     :integer          not null, primary key
#  position               :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  exercise_id            :integer          not null
#  workout_routine_day_id :integer          not null
#
# Indexes
#
#  index_workout_routine_day_exercises_on_exercise_id             (exercise_id)
#  index_workout_routine_day_exercises_on_workout_routine_day_id  (workout_routine_day_id)
#
# Foreign Keys
#
#  exercise_id             (exercise_id => exercises.id)
#  workout_routine_day_id  (workout_routine_day_id => workout_routine_days.id)
#

require "test_helper"

class WorkoutRoutineDayExerciseTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
