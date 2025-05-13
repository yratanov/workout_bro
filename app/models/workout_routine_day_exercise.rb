# == Schema Information
#
# Table name: workout_routine_day_exercises
#
#  id                     :integer          not null, primary key
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

class WorkoutRoutineDayExercise < ApplicationRecord
  belongs_to :workout_routine_day
  belongs_to :exercise
end
