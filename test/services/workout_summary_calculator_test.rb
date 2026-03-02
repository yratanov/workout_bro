require "test_helper"

class WorkoutSummaryCalculatorTest < ActiveSupport::TestCase
  setup do
    @user = users(:john)
    @bench_press = exercises(:bench_press)
    @squat = exercises(:squat)
    @pull_up = exercises(:pull_up)
    @push_day = workout_routine_days(:push_day)
    @user.workouts.destroy_all
  end

  test "calculates total volume correctly" do
    workout = create_strength_workout(workout_routine_day: @push_day)
    workout_set =
      workout.workout_sets.create!(
        exercise: @bench_press,
        started_at: 30.minutes.ago,
        ended_at: 20.minutes.ago
      )
    workout_set.workout_reps.create!(weight: 100, reps: 10)
    workout_set.workout_reps.create!(weight: 90, reps: 8)
    workout_set.workout_reps.create!(weight: 80, reps: 6)

    result = WorkoutSummaryCalculator.new(workout: workout).call
    assert_equal 2200, result.total_volume
  end

  test "counts total sets" do
    workout = create_strength_workout(workout_routine_day: @push_day)
    workout.workout_sets.create!(
      exercise: @bench_press,
      started_at: 30.minutes.ago,
      ended_at: 20.minutes.ago
    )
    workout.workout_sets.create!(
      exercise: @squat,
      started_at: 15.minutes.ago,
      ended_at: 5.minutes.ago
    )

    result = WorkoutSummaryCalculator.new(workout: workout).call
    assert_equal 2, result.total_sets
  end

  test "counts total reps" do
    workout = create_strength_workout(workout_routine_day: @push_day)
    workout_set =
      workout.workout_sets.create!(
        exercise: @bench_press,
        started_at: 30.minutes.ago,
        ended_at: 20.minutes.ago
      )
    workout_set.workout_reps.create!(weight: 100, reps: 10)
    workout_set.workout_reps.create!(weight: 90, reps: 8)

    result = WorkoutSummaryCalculator.new(workout: workout).call
    assert_equal 18, result.total_reps
  end

  test "returns unique muscles worked" do
    workout = create_strength_workout(workout_routine_day: @push_day)
    workout.workout_sets.create!(
      exercise: @bench_press,
      started_at: 30.minutes.ago,
      ended_at: 20.minutes.ago
    )
    workout.workout_sets.create!(
      exercise: @squat,
      started_at: 15.minutes.ago,
      ended_at: 5.minutes.ago
    )

    result = WorkoutSummaryCalculator.new(workout: workout).call
    muscle_names = result.muscles_worked.map(&:name).sort
    assert_equal %w[chest legs], muscle_names
  end

  test "returns workout duration" do
    workout = create_strength_workout(workout_routine_day: @push_day)
    result = WorkoutSummaryCalculator.new(workout: workout).call
    assert_equal workout.time_in_seconds, result.duration
  end

  test "finds previous workout by workout_routine_day_id" do
    previous_workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.week.ago,
        ended_at: 1.week.ago + 1.hour,
        workout_routine_day: @push_day
      )
    workout = create_strength_workout(workout_routine_day: @push_day)

    result = WorkoutSummaryCalculator.new(workout: workout).call
    assert_equal previous_workout, result.previous_workout
  end

  test "finds previous workout by exercise overlap for custom workouts" do
    custom_workout = create_strength_workout(workout_routine_day: nil)
    custom_workout.workout_sets.create!(
      exercise: @bench_press,
      started_at: 30.minutes.ago
    )
    custom_workout.workout_sets.create!(
      exercise: @squat,
      started_at: 20.minutes.ago
    )

    previous_custom =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.week.ago,
        ended_at: 1.week.ago + 1.hour,
        workout_routine_day: nil
      )
    previous_custom.workout_sets.create!(
      exercise: @bench_press,
      started_at: 1.week.ago + 10.minutes
    )
    previous_custom.workout_sets.create!(
      exercise: @squat,
      started_at: 1.week.ago + 20.minutes
    )

    result = WorkoutSummaryCalculator.new(workout: custom_workout).call
    assert_equal previous_custom, result.previous_workout
  end

  test "does not match previous workout with insufficient overlap" do
    custom_workout = create_strength_workout(workout_routine_day: nil)
    custom_workout.workout_sets.create!(
      exercise: @bench_press,
      started_at: 30.minutes.ago
    )
    custom_workout.workout_sets.create!(
      exercise: @squat,
      started_at: 25.minutes.ago
    )
    custom_workout.workout_sets.create!(
      exercise: @pull_up,
      started_at: 20.minutes.ago
    )

    previous_custom =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.week.ago,
        ended_at: 1.week.ago + 1.hour,
        workout_routine_day: nil
      )
    previous_custom.workout_sets.create!(
      exercise: @bench_press,
      started_at: 1.week.ago + 10.minutes
    )

    result = WorkoutSummaryCalculator.new(workout: custom_workout).call
    assert_nil result.previous_workout
  end

  test "calculates volume comparison as percentage" do
    previous_workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.week.ago,
        ended_at: 1.week.ago + 1.hour,
        workout_routine_day: @push_day
      )
    prev_set =
      previous_workout.workout_sets.create!(
        exercise: @bench_press,
        started_at: 1.week.ago + 10.minutes
      )
    prev_set.workout_reps.create!(weight: 100, reps: 10)

    workout = create_strength_workout(workout_routine_day: @push_day)
    current_set =
      workout.workout_sets.create!(
        exercise: @bench_press,
        started_at: 30.minutes.ago
      )
    current_set.workout_reps.create!(weight: 100, reps: 12)

    result = WorkoutSummaryCalculator.new(workout: workout).call
    assert_equal 200, result.comparison.volume_diff
    assert_equal 20.0, result.comparison.volume_diff_percent
  end

  test "includes passed PRs in summary" do
    workout = create_strength_workout(workout_routine_day: @push_day)
    workout_set =
      workout.workout_sets.create!(
        exercise: @bench_press,
        started_at: 30.minutes.ago
      )
    rep = workout_set.workout_reps.create!(weight: 100, reps: 10)
    pr =
      @user.personal_records.create!(
        exercise: @bench_press,
        workout: workout,
        workout_rep: rep,
        pr_type: :max_weight,
        weight: 100,
        reps: 10,
        achieved_on: Date.current
      )

    result = WorkoutSummaryCalculator.new(workout: workout, new_prs: [pr]).call
    assert_equal [pr], result.new_prs
  end

  test "returns run-specific stats" do
    run_workout =
      Workout.create!(
        user: @user,
        workout_type: :run,
        started_at: 30.minutes.ago,
        ended_at: Time.current,
        distance: 5000,
        time_in_seconds: 1800
      )

    result = WorkoutSummaryCalculator.new(workout: run_workout).call
    assert_equal 5000, result.distance
    assert_equal 1800, result.duration
    assert_equal 360.0, result.pace
  end

  test "finds previous run for comparison" do
    previous_run =
      Workout.create!(
        user: @user,
        workout_type: :run,
        started_at: 1.week.ago,
        ended_at: 1.week.ago + 30.minutes,
        distance: 5000,
        time_in_seconds: 1800
      )

    run_workout =
      Workout.create!(
        user: @user,
        workout_type: :run,
        started_at: 30.minutes.ago,
        ended_at: Time.current,
        distance: 5000,
        time_in_seconds: 1800
      )

    result = WorkoutSummaryCalculator.new(workout: run_workout).call
    assert_equal previous_run, result.previous_workout
  end

  test "calculates pace difference in seconds" do
    prev_start = 1.week.ago
    Workout.create!(
      user: @user,
      workout_type: :run,
      started_at: prev_start,
      ended_at: prev_start + 1800.seconds,
      distance: 5000,
      time_in_seconds: 1800
    )

    current_start = 1.hour.ago
    faster_run =
      Workout.create!(
        user: @user,
        workout_type: :run,
        started_at: current_start,
        ended_at: current_start + 1725.seconds,
        distance: 5000,
        time_in_seconds: 1725
      )

    result = WorkoutSummaryCalculator.new(workout: faster_run).call
    assert_equal 15.0, result.comparison.pace_diff
  end

  test "handles workout with no sets" do
    workout = create_strength_workout(workout_routine_day: @push_day)
    result = WorkoutSummaryCalculator.new(workout: workout).call

    assert_equal 0, result.total_volume
    assert_equal 0, result.total_sets
    assert_equal 0, result.total_reps
    assert result.muscles_worked.empty?
  end

  test "handles exercises without muscle association" do
    exercise_without_muscle =
      Exercise.create!(
        name: "Mystery Exercise",
        user: @user,
        with_weights: true,
        muscle: nil
      )

    workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        ended_at: Time.current
      )
    workout.workout_sets.create!(
      exercise: exercise_without_muscle,
      started_at: 30.minutes.ago
    )

    result = WorkoutSummaryCalculator.new(workout: workout).call
    assert result.muscles_worked.empty?
  end

  test "returns nil comparison when no previous workout" do
    workout = create_strength_workout(workout_routine_day: nil)
    result = WorkoutSummaryCalculator.new(workout: workout).call

    assert_nil result.previous_workout
    assert_nil result.comparison
  end

  test "handles reps with nil weight for bodyweight exercises" do
    workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        ended_at: Time.current
      )
    workout_set =
      workout.workout_sets.create!(
        exercise: @pull_up,
        started_at: 30.minutes.ago
      )
    workout_set.workout_reps.create!(weight: nil, reps: 10)

    result = WorkoutSummaryCalculator.new(workout: workout).call
    assert_equal 0, result.total_volume
    assert_equal 10, result.total_reps
  end

  private

  def create_strength_workout(workout_routine_day:)
    Workout.create!(
      user: @user,
      workout_type: :strength,
      started_at: 1.hour.ago,
      ended_at: Time.current,
      workout_routine_day: workout_routine_day
    )
  end
end
