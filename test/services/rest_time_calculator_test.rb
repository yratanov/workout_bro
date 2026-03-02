require "test_helper"

class RestTimeCalculatorTest < ActiveSupport::TestCase
  setup do
    @user = users(:john)
    @bench_press = exercises(:bench_press)
    @squat = exercises(:squat)
    @bicep_curl = exercises(:bicep_curl)
    @workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago
      )
  end

  test "returns base rest time of 60 seconds for small muscle group and light weight" do
    workout_set =
      @workout.workout_sets.create!(
        exercise: @bicep_curl,
        started_at: 30.minutes.ago
      )
    workout_set.workout_reps.create!(weight: 10, reps: 10)

    result =
      RestTimeCalculator.new(
        workout_set: workout_set,
        user: @user
      ).recommended_seconds
    assert_equal 60, result
  end

  test "adds 30 seconds for large muscle groups" do
    workout_set =
      @workout.workout_sets.create!(
        exercise: @squat,
        started_at: 30.minutes.ago
      )
    workout_set.workout_reps.create!(weight: 50, reps: 10)

    result =
      RestTimeCalculator.new(
        workout_set: workout_set,
        user: @user
      ).recommended_seconds
    assert_equal 90, result
  end

  test "adds 30 seconds for heavy lifts at or above 85 percent of PR" do
    create_bicep_curl_pr(weight: 20)

    workout_set =
      @workout.workout_sets.create!(
        exercise: @bicep_curl,
        started_at: 30.minutes.ago
      )
    workout_set.workout_reps.create!(weight: 17, reps: 10)

    result =
      RestTimeCalculator.new(
        workout_set: workout_set,
        user: @user
      ).recommended_seconds
    assert_equal 90, result
  end

  test "does not add extra time for lighter lifts below 85 percent of PR" do
    create_bicep_curl_pr(weight: 20)

    workout_set =
      @workout.workout_sets.create!(
        exercise: @bicep_curl,
        started_at: 30.minutes.ago
      )
    workout_set.workout_reps.create!(weight: 16, reps: 10)

    result =
      RestTimeCalculator.new(
        workout_set: workout_set,
        user: @user
      ).recommended_seconds
    assert_equal 60, result
  end

  test "adds 60 seconds total for both large muscle group and heavy lift" do
    create_squat_pr(weight: 150)

    workout_set =
      @workout.workout_sets.create!(
        exercise: @squat,
        started_at: 30.minutes.ago
      )
    workout_set.workout_reps.create!(weight: 140, reps: 5)

    result =
      RestTimeCalculator.new(
        workout_set: workout_set,
        user: @user
      ).recommended_seconds
    assert_equal 120, result
  end

  test "returns base rest time for small muscle with no reps yet" do
    workout_set =
      @workout.workout_sets.create!(
        exercise: @bicep_curl,
        started_at: 30.minutes.ago
      )

    result =
      RestTimeCalculator.new(
        workout_set: workout_set,
        user: @user
      ).recommended_seconds
    assert_equal 60, result
  end

  test "returns base rest time for exercise without muscle" do
    exercise_without_muscle =
      Exercise.create!(
        name: "Mystery Exercise",
        user: @user,
        with_weights: true,
        muscle: nil
      )
    workout_set =
      @workout.workout_sets.create!(
        exercise: exercise_without_muscle,
        started_at: 30.minutes.ago
      )
    workout_set.workout_reps.create!(weight: 50, reps: 10)

    result =
      RestTimeCalculator.new(
        workout_set: workout_set,
        user: @user
      ).recommended_seconds
    assert_equal 60, result
  end

  private

  def create_bicep_curl_pr(weight:)
    pr_workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 2.weeks.ago,
        ended_at: 2.weeks.ago + 1.hour
      )
    pr_set =
      pr_workout.workout_sets.create!(
        exercise: @bicep_curl,
        started_at: 2.weeks.ago + 10.minutes,
        ended_at: 2.weeks.ago + 20.minutes
      )
    pr_rep = pr_set.workout_reps.create!(weight: weight, reps: 10)
    @user.personal_records.create!(
      exercise: @bicep_curl,
      workout: pr_workout,
      workout_rep: pr_rep,
      pr_type: :max_weight,
      weight: weight,
      reps: 10,
      achieved_on: 2.weeks.ago.to_date
    )
  end

  def create_squat_pr(weight:)
    pr_workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 2.weeks.ago,
        ended_at: 2.weeks.ago + 1.hour
      )
    pr_set =
      pr_workout.workout_sets.create!(
        exercise: @squat,
        started_at: 2.weeks.ago + 10.minutes,
        ended_at: 2.weeks.ago + 20.minutes
      )
    pr_rep = pr_set.workout_reps.create!(weight: weight, reps: 5)
    @user.personal_records.create!(
      exercise: @squat,
      workout: pr_workout,
      workout_rep: pr_rep,
      pr_type: :max_weight,
      weight: weight,
      reps: 5,
      achieved_on: 2.weeks.ago.to_date
    )
  end
end
