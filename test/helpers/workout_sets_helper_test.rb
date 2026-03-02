require "test_helper"

class WorkoutSetsHelperTest < ActionView::TestCase
  # user_supersets tests

  setup { Current.session = Session.create!(user: users(:john)) }

  teardown { Current.reset }

  test "user_supersets returns supersets that have exercises" do
    result = user_supersets

    assert_includes result, supersets(:push_pull)
    assert_includes result, supersets(:arm_circuit)
  end

  test "user_supersets excludes supersets without exercises" do
    empty_superset = Superset.create!(name: "Empty", user: users(:john))

    result = user_supersets

    assert_not_includes result, empty_superset
  end

  test "user_supersets only returns current user supersets" do
    other_user_superset = Superset.create!(name: "Other", user: users(:jane))
    SupersetExercise.create!(
      superset: other_user_superset,
      exercise: exercises(:bench_press),
      position: 1
    )

    result = user_supersets

    assert_not_includes result, other_user_superset
  end

  # next_routine_item_for_workout tests

  test "next_routine_item_for_workout returns default item when workout has no routine day" do
    workout =
      Workout.new(
        workout_type: :strength,
        started_at: Time.current,
        user: users(:john)
      )

    result = next_routine_item_for_workout(workout)

    assert_equal false, result.is_superset
    assert_nil result.superset_id
    assert_nil result.exercise_id
  end

  test "next_routine_item_for_workout returns the first uncompleted exercise" do
    workout = workouts(:completed_workout)

    result = next_routine_item_for_workout(workout)

    assert_equal false, result.is_superset
  end

  test "next_routine_item_for_workout returns the next exercise when first is completed" do
    workout = workouts(:completed_workout)
    routine_day = workout_routine_days(:push_day)
    WorkoutRoutineDayExercise.create!(
      workout_routine_day: routine_day,
      exercise: exercises(:squat),
      position: 2
    )

    result = next_routine_item_for_workout(workout)

    assert_equal false, result.is_superset
    assert_equal exercises(:squat).id, result.exercise_id
  end

  test "next_routine_item_for_workout returns the superset as the next item" do
    workout =
      Workout.create!(
        workout_type: :strength,
        started_at: Time.current,
        user: users(:john),
        workout_routine_day: workout_routine_days(:push_day)
      )

    workout_routine_days(:push_day).workout_routine_day_exercises.destroy_all

    WorkoutRoutineDayExercise.create!(
      workout_routine_day: workout_routine_days(:push_day),
      superset: supersets(:push_pull),
      position: 1
    )

    result = next_routine_item_for_workout(workout)

    assert result.is_superset
    assert_equal supersets(:push_pull).id, result.superset_id
    assert_nil result.exercise_id
  end

  test "next_routine_item_for_workout skips completed supersets" do
    workout =
      Workout.create!(
        workout_type: :strength,
        started_at: Time.current,
        user: users(:john),
        workout_routine_day: workout_routine_days(:push_day)
      )

    workout_routine_days(:push_day).workout_routine_day_exercises.destroy_all

    WorkoutRoutineDayExercise.create!(
      workout_routine_day: workout_routine_days(:push_day),
      superset: supersets(:push_pull),
      position: 1
    )

    WorkoutSet.create!(
      workout: workout,
      exercise: exercises(:bench_press),
      superset: supersets(:push_pull),
      superset_group: 1,
      started_at: Time.current
    )

    WorkoutRoutineDayExercise.create!(
      workout_routine_day: workout_routine_days(:push_day),
      exercise: exercises(:squat),
      position: 2
    )

    result = next_routine_item_for_workout(workout)

    assert_equal false, result.is_superset
    assert_equal exercises(:squat).id, result.exercise_id
  end

  test "next_routine_item_for_workout with mixed items returns first exercise when nothing completed" do
    workout =
      Workout.create!(
        workout_type: :strength,
        started_at: Time.current,
        user: users(:john),
        workout_routine_day: workout_routine_days(:push_day)
      )

    workout_routine_days(:push_day).workout_routine_day_exercises.destroy_all

    WorkoutRoutineDayExercise.create!(
      workout_routine_day: workout_routine_days(:push_day),
      exercise: exercises(:bench_press),
      position: 1
    )
    WorkoutRoutineDayExercise.create!(
      workout_routine_day: workout_routine_days(:push_day),
      superset: supersets(:push_pull),
      position: 2
    )
    WorkoutRoutineDayExercise.create!(
      workout_routine_day: workout_routine_days(:push_day),
      exercise: exercises(:squat),
      position: 3
    )

    result = next_routine_item_for_workout(workout)

    assert_equal false, result.is_superset
    assert_equal exercises(:bench_press).id, result.exercise_id
  end

  test "next_routine_item_for_workout with mixed items returns superset after first exercise completed" do
    workout =
      Workout.create!(
        workout_type: :strength,
        started_at: Time.current,
        user: users(:john),
        workout_routine_day: workout_routine_days(:push_day)
      )

    workout_routine_days(:push_day).workout_routine_day_exercises.destroy_all

    WorkoutRoutineDayExercise.create!(
      workout_routine_day: workout_routine_days(:push_day),
      exercise: exercises(:bench_press),
      position: 1
    )
    WorkoutRoutineDayExercise.create!(
      workout_routine_day: workout_routine_days(:push_day),
      superset: supersets(:push_pull),
      position: 2
    )
    WorkoutRoutineDayExercise.create!(
      workout_routine_day: workout_routine_days(:push_day),
      exercise: exercises(:squat),
      position: 3
    )

    WorkoutSet.create!(
      workout: workout,
      exercise: exercises(:bench_press),
      started_at: Time.current
    )

    result = next_routine_item_for_workout(workout)

    assert result.is_superset
    assert_equal supersets(:push_pull).id, result.superset_id
  end

  test "next_routine_item_for_workout with mixed items returns last exercise after superset completed" do
    workout =
      Workout.create!(
        workout_type: :strength,
        started_at: Time.current,
        user: users(:john),
        workout_routine_day: workout_routine_days(:push_day)
      )

    workout_routine_days(:push_day).workout_routine_day_exercises.destroy_all

    WorkoutRoutineDayExercise.create!(
      workout_routine_day: workout_routine_days(:push_day),
      exercise: exercises(:bench_press),
      position: 1
    )
    WorkoutRoutineDayExercise.create!(
      workout_routine_day: workout_routine_days(:push_day),
      superset: supersets(:push_pull),
      position: 2
    )
    WorkoutRoutineDayExercise.create!(
      workout_routine_day: workout_routine_days(:push_day),
      exercise: exercises(:squat),
      position: 3
    )

    WorkoutSet.create!(
      workout: workout,
      exercise: exercises(:bench_press),
      started_at: Time.current
    )
    WorkoutSet.create!(
      workout: workout,
      exercise: exercises(:pull_up),
      superset: supersets(:push_pull),
      superset_group: 1,
      started_at: Time.current
    )

    result = next_routine_item_for_workout(workout)

    assert_equal false, result.is_superset
    assert_equal exercises(:squat).id, result.exercise_id
  end

  # available_exercises_for_workout_set tests

  test "available_exercises_for_workout_set includes routine exercises first when workout has routine day" do
    workout = workouts(:active_workout)
    workout_set = WorkoutSet.new(workout: workout)

    result = available_exercises_for_workout_set(workout_set)

    assert_not_includes result, exercises(:bench_press)
  end

  test "available_exercises_for_workout_set excludes exercises already in workout" do
    workout = workouts(:active_workout)
    workout_set = WorkoutSet.new(workout: workout)

    result = available_exercises_for_workout_set(workout_set)

    assert_not_includes result, exercises(:bench_press)
  end

  test "available_exercises_for_workout_set includes other user exercises" do
    workout = workouts(:active_workout)
    workout_set = WorkoutSet.new(workout: workout)

    result = available_exercises_for_workout_set(workout_set)

    assert_includes result, exercises(:squat)
    assert_includes result, exercises(:deadlift)
  end

  test "available_exercises_for_workout_set returns all user exercises when no routine day" do
    workout =
      Workout.create!(
        workout_type: :strength,
        started_at: Time.current,
        user: users(:john)
      )
    workout_set = WorkoutSet.new(workout: workout)

    result = available_exercises_for_workout_set(workout_set)

    assert_includes result, exercises(:bench_press)
    assert_includes result, exercises(:squat)
    assert_includes result, exercises(:deadlift)
  end

  test "available_exercises_for_workout_set excludes exercises already in workout when no routine day" do
    workout =
      Workout.create!(
        workout_type: :strength,
        started_at: Time.current,
        user: users(:john)
      )
    WorkoutSet.create!(
      workout: workout,
      exercise: exercises(:bench_press),
      started_at: Time.current
    )
    workout_set = WorkoutSet.new(workout: workout)

    result = available_exercises_for_workout_set(workout_set)

    assert_not_includes result, exercises(:bench_press)
    assert_includes result, exercises(:squat)
  end

  # last_completed_workout_set tests

  test "last_completed_workout_set returns the last completed set" do
    workout = workouts(:completed_workout)

    result = last_completed_workout_set(workout)

    assert_equal workout_sets(:completed_set), result
  end

  test "last_completed_workout_set returns nil when no completed sets" do
    workout = workouts(:active_workout)

    result = last_completed_workout_set(workout)

    assert_nil result
  end

  test "last_completed_workout_set returns the most recently ended set" do
    workout = workouts(:completed_workout)
    WorkoutSet.create!(
      workout: workout,
      exercise: exercises(:squat),
      started_at: 2.hours.ago,
      ended_at: 1.hour.ago
    )
    later_set =
      WorkoutSet.create!(
        workout: workout,
        exercise: exercises(:deadlift),
        started_at: 30.minutes.ago,
        ended_at: 10.minutes.ago
      )

    result = last_completed_workout_set(workout)

    assert_equal later_set, result
  end
end
