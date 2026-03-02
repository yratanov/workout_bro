require "test_helper"

# == Schema Information
#
# Table name: workout_routine_day_exercises
# Database name: primary
#
#  id                     :integer          not null, primary key
#  comment                :text
#  position               :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  exercise_id            :integer
#  superset_id            :integer
#  workout_routine_day_id :integer          not null
#
# Indexes
#
#  index_workout_routine_day_exercises_on_exercise_id             (exercise_id)
#  index_workout_routine_day_exercises_on_superset_id             (superset_id)
#  index_workout_routine_day_exercises_on_workout_routine_day_id  (workout_routine_day_id)
#
# Foreign Keys
#
#  exercise_id             (exercise_id => exercises.id)
#  superset_id             (superset_id => supersets.id)
#  workout_routine_day_id  (workout_routine_day_id => workout_routine_days.id)
#

class WorkoutRoutineDayExerciseTest < ActiveSupport::TestCase
  test "is valid with only exercise" do
    wrde =
      WorkoutRoutineDayExercise.new(
        workout_routine_day: workout_routine_days(:push_day),
        exercise: exercises(:squat)
      )
    assert wrde.valid?
  end

  test "is valid with only superset" do
    wrde =
      WorkoutRoutineDayExercise.new(
        workout_routine_day: workout_routine_days(:push_day),
        superset: supersets(:push_pull)
      )
    assert wrde.valid?
  end

  test "is invalid without exercise or superset" do
    wrde =
      WorkoutRoutineDayExercise.new(
        workout_routine_day: workout_routine_days(:push_day)
      )
    assert_not wrde.valid?
    assert_includes wrde.errors[:base],
                    I18n.t("errors.messages.exercise_or_superset_required")
  end

  test "is invalid with both exercise and superset" do
    wrde =
      WorkoutRoutineDayExercise.new(
        workout_routine_day: workout_routine_days(:push_day),
        exercise: exercises(:squat),
        superset: supersets(:push_pull)
      )
    assert_not wrde.valid?
    assert_includes wrde.errors[:base],
                    I18n.t("errors.messages.exercise_xor_superset")
  end

  test "superset? returns true when superset_id is present" do
    wrde =
      WorkoutRoutineDayExercise.new(
        workout_routine_day: workout_routine_days(:push_day),
        superset: supersets(:push_pull)
      )
    assert wrde.superset?
  end

  test "superset? returns false when superset_id is blank" do
    wrde =
      WorkoutRoutineDayExercise.new(
        workout_routine_day: workout_routine_days(:push_day),
        exercise: exercises(:squat)
      )
    refute wrde.superset?
  end

  test "display_name returns exercise name when has exercise" do
    wrde =
      WorkoutRoutineDayExercise.new(
        workout_routine_day: workout_routine_days(:push_day),
        exercise: exercises(:squat)
      )
    assert_equal "Squat", wrde.display_name
  end

  test "display_name returns superset display_name when has superset" do
    wrde =
      WorkoutRoutineDayExercise.new(
        workout_routine_day: workout_routine_days(:push_day),
        superset: supersets(:push_pull)
      )
    assert_equal "Push Pull", wrde.display_name
  end
end
