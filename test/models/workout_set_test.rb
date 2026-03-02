require "test_helper"

# == Schema Information
#
# Table name: workout_sets
# Database name: primary
#
#  id                   :integer          not null, primary key
#  ended_at             :datetime
#  notes                :text
#  paused_at            :datetime
#  started_at           :datetime
#  superset_group       :integer
#  total_paused_seconds :integer          default(0)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  exercise_id          :integer          not null
#  superset_id          :integer
#  workout_id           :integer          not null
#
# Indexes
#
#  index_workout_sets_on_exercise_id                    (exercise_id)
#  index_workout_sets_on_superset_id                    (superset_id)
#  index_workout_sets_on_workout_id_and_superset_group  (workout_id,superset_group)
#
# Foreign Keys
#
#  exercise_id  (exercise_id => exercises.id) ON DELETE => restrict
#  superset_id  (superset_id => supersets.id)
#  workout_id   (workout_id => workouts.id)
#

class WorkoutSetTest < ActiveSupport::TestCase
  test "default_rep_values returns values from previous workout rep at same index" do
    user = users(:john)
    exercise = exercises(:bench_press)

    # Create a completed workout with reps
    old_workout =
      Workout.create!(
        user: user,
        workout_type: "strength",
        started_at: 2.days.ago,
        ended_at: 2.days.ago + 1.hour
      )
    old_set =
      WorkoutSet.create!(
        workout: old_workout,
        exercise: exercise,
        started_at: 2.days.ago,
        ended_at: 2.days.ago + 10.minutes
      )
    old_set.workout_reps.create!(reps: 12, weight: 80, band: "heavy")
    old_set.workout_reps.create!(reps: 10, weight: 85, band: "medium")

    # Create current workout set with one rep already
    current_workout =
      Workout.create!(
        user: user,
        workout_type: "strength",
        started_at: 1.hour.ago
      )
    current_set =
      WorkoutSet.create!(
        workout: current_workout,
        exercise: exercise,
        started_at: 1.hour.ago
      )
    current_set.workout_reps.create!(reps: 15, weight: 70, band: nil)

    # Should get values from old_set's second rep (index 1)
    defaults = current_set.default_rep_values
    assert_equal 10, defaults[:reps]
    assert_equal 85, defaults[:weight]
    assert_equal "medium", defaults[:band]
  end

  test "default_rep_values returns values from last rep in current set when no previous rep at same index" do
    user = users(:john)
    exercise = exercises(:bench_press)

    # Create a completed workout with only one rep
    old_workout =
      Workout.create!(
        user: user,
        workout_type: "strength",
        started_at: 2.days.ago,
        ended_at: 2.days.ago + 1.hour
      )
    old_set =
      WorkoutSet.create!(
        workout: old_workout,
        exercise: exercise,
        started_at: 2.days.ago,
        ended_at: 2.days.ago + 10.minutes
      )
    old_set.workout_reps.create!(reps: 12, weight: 80, band: nil)

    # Create current workout set with two reps already (so index 2 won't exist in old_set)
    current_workout =
      Workout.create!(
        user: user,
        workout_type: "strength",
        started_at: 1.hour.ago
      )
    current_set =
      WorkoutSet.create!(
        workout: current_workout,
        exercise: exercise,
        started_at: 1.hour.ago
      )
    current_set.workout_reps.create!(reps: 15, weight: 70, band: nil)
    current_set.workout_reps.create!(reps: 14, weight: 75, band: "light")

    # Should get values from current_set's last rep
    defaults = current_set.default_rep_values
    assert_equal 14, defaults[:reps]
    assert_equal 75, defaults[:weight]
    assert_equal "light", defaults[:band]
  end

  test "default_rep_values returns default values when no previous reps" do
    user = users(:john)
    new_exercise = Exercise.create!(name: "New Exercise", user: user)

    current_workout =
      Workout.create!(
        user: user,
        workout_type: "strength",
        started_at: 1.hour.ago
      )
    current_set =
      WorkoutSet.create!(
        workout: current_workout,
        exercise: new_exercise,
        started_at: 1.hour.ago
      )

    defaults = current_set.default_rep_values
    assert_equal 10, defaults[:reps]
    assert_equal 10, defaults[:weight]
    assert_nil defaults[:band]
  end

  test "in_superset? returns true when has both superset_id and superset_group" do
    user = users(:john)
    workout =
      Workout.create!(
        user: user,
        workout_type: "strength",
        started_at: 1.hour.ago
      )
    set =
      WorkoutSet.new(
        workout: workout,
        exercise: exercises(:bench_press),
        superset: supersets(:push_pull),
        superset_group: 1
      )
    assert set.in_superset?
  end

  test "in_superset? returns false when only has superset_id" do
    user = users(:john)
    workout =
      Workout.create!(
        user: user,
        workout_type: "strength",
        started_at: 1.hour.ago
      )
    set =
      WorkoutSet.new(
        workout: workout,
        exercise: exercises(:bench_press),
        superset: supersets(:push_pull)
      )
    refute set.in_superset?
  end

  test "in_superset? returns false when only has superset_group" do
    user = users(:john)
    workout =
      Workout.create!(
        user: user,
        workout_type: "strength",
        started_at: 1.hour.ago
      )
    set =
      WorkoutSet.new(
        workout: workout,
        exercise: exercises(:bench_press),
        superset_group: 1
      )
    refute set.in_superset?
  end

  test "in_superset? returns false when has neither" do
    user = users(:john)
    workout =
      Workout.create!(
        user: user,
        workout_type: "strength",
        started_at: 1.hour.ago
      )
    set = WorkoutSet.new(workout: workout, exercise: exercises(:bench_press))
    refute set.in_superset?
  end

  test "superset_sibling_sets returns other sets in the same superset group" do
    user = users(:john)
    workout =
      Workout.create!(
        user: user,
        workout_type: "strength",
        started_at: 1.hour.ago
      )
    superset = supersets(:push_pull)

    set1 =
      WorkoutSet.create!(
        workout: workout,
        exercise: exercises(:bench_press),
        superset: superset,
        superset_group: 1
      )
    set2 =
      WorkoutSet.create!(
        workout: workout,
        exercise: exercises(:pull_up),
        superset: superset,
        superset_group: 1
      )

    assert_includes set1.superset_sibling_sets, set2
    assert_not_includes set1.superset_sibling_sets, set1
  end

  test "superset_sibling_sets excludes sets from different superset groups" do
    user = users(:john)
    workout =
      Workout.create!(
        user: user,
        workout_type: "strength",
        started_at: 1.hour.ago
      )
    superset = supersets(:push_pull)

    set1 =
      WorkoutSet.create!(
        workout: workout,
        exercise: exercises(:bench_press),
        superset: superset,
        superset_group: 1
      )
    set2 =
      WorkoutSet.create!(
        workout: workout,
        exercise: exercises(:pull_up),
        superset: superset,
        superset_group: 2
      )

    assert_not_includes set1.superset_sibling_sets, set2
  end

  test "superset_sibling_sets returns empty when not in a superset" do
    user = users(:john)
    workout =
      Workout.create!(
        user: user,
        workout_type: "strength",
        started_at: 1.hour.ago
      )
    set =
      WorkoutSet.create!(workout: workout, exercise: exercises(:bench_press))
    assert_empty set.superset_sibling_sets
  end

  test "all_superset_sets returns all sets in the same superset group including self" do
    user = users(:john)
    workout =
      Workout.create!(
        user: user,
        workout_type: "strength",
        started_at: 1.hour.ago
      )
    superset = supersets(:push_pull)

    set1 =
      WorkoutSet.create!(
        workout: workout,
        exercise: exercises(:bench_press),
        superset: superset,
        superset_group: 1
      )
    set2 =
      WorkoutSet.create!(
        workout: workout,
        exercise: exercises(:pull_up),
        superset: superset,
        superset_group: 1
      )

    assert_includes set1.all_superset_sets, set1
    assert_includes set1.all_superset_sets, set2
  end

  test "all_superset_sets returns empty when not in a superset" do
    user = users(:john)
    workout =
      Workout.create!(
        user: user,
        workout_type: "strength",
        started_at: 1.hour.ago
      )
    set =
      WorkoutSet.create!(workout: workout, exercise: exercises(:bench_press))
    assert_empty set.all_superset_sets
  end
end
