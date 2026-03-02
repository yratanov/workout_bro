require "test_helper"

# == Schema Information
#
# Table name: superset_exercises
# Database name: primary
#
#  id          :integer          not null, primary key
#  position    :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  exercise_id :integer          not null
#  superset_id :integer          not null
#
# Indexes
#
#  index_superset_exercises_on_exercise_id                  (exercise_id)
#  index_superset_exercises_on_superset_id_and_exercise_id  (superset_id,exercise_id) UNIQUE
#  index_superset_exercises_on_superset_id_and_position     (superset_id,position)
#
# Foreign Keys
#
#  exercise_id  (exercise_id => exercises.id)
#  superset_id  (superset_id => supersets.id)
#

class SupersetExerciseTest < ActiveSupport::TestCase
  test "requires a position" do
    se =
      SupersetExercise.new(
        superset: supersets(:push_pull),
        exercise: exercises(:squat)
      )
    assert_not se.valid?
    assert_includes se.errors[:position], "can't be blank"
  end

  test "requires position to be greater than 0" do
    se =
      SupersetExercise.new(
        superset: supersets(:push_pull),
        exercise: exercises(:squat),
        position: 0
      )
    assert_not se.valid?
    assert_includes se.errors[:position], "must be greater than 0"
  end

  test "does not allow duplicate exercise in same superset" do
    se =
      SupersetExercise.new(
        superset: supersets(:push_pull),
        exercise: exercises(:bench_press),
        position: 3
      )
    assert_not se.valid?
    assert_includes se.errors[:exercise_id], "has already been taken"
  end

  test "allows same exercise in different supersets" do
    se =
      SupersetExercise.new(
        superset: supersets(:arm_circuit),
        exercise: exercises(:bench_press),
        position: 3
      )
    assert se.valid?
  end

  test "is valid with all required attributes" do
    se =
      SupersetExercise.new(
        superset: supersets(:push_pull),
        exercise: exercises(:squat),
        position: 3
      )
    assert se.valid?
  end

  test "belongs to a superset" do
    superset_exercise = superset_exercises(:push_pull_bench)
    assert_equal supersets(:push_pull), superset_exercise.superset
  end

  test "belongs to an exercise" do
    superset_exercise = superset_exercises(:push_pull_bench)
    assert_equal exercises(:bench_press), superset_exercise.exercise
  end
end
