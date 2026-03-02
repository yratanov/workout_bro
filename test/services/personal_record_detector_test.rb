require "test_helper"

class PersonalRecordDetectorTest < ActiveSupport::TestCase
  setup do
    @user = users(:john)
    @bench_press = exercises(:bench_press)
    @pull_up = exercises(:pull_up)
    @banded_squat = exercises(:banded_squat)
  end

  test "creates max_weight and max_volume PR for first weighted lift" do
    workout = create_completed_strength_workout
    workout_set =
      workout.workout_sets.create!(
        exercise: @bench_press,
        started_at: 1.hour.ago
      )
    workout_set.workout_reps.create!(weight: 100, reps: 10)

    prs = PersonalRecordDetector.new(workout: workout).call

    assert_equal 2, prs.count
    assert_equal %w[max_volume max_weight], prs.map(&:pr_type).sort
  end

  test "creates max_volume PR with correct volume" do
    workout = create_completed_strength_workout
    workout_set =
      workout.workout_sets.create!(
        exercise: @bench_press,
        started_at: 1.hour.ago
      )
    workout_set.workout_reps.create!(weight: 50, reps: 20)

    prs = PersonalRecordDetector.new(workout: workout).call

    volume_pr = prs.find(&:max_volume?)
    assert_equal 1000, volume_pr.volume
  end

  test "does not create PR if weight is below existing PR" do
    workout = create_completed_strength_workout
    workout_set =
      workout.workout_sets.create!(
        exercise: @bench_press,
        started_at: 1.hour.ago
      )
    rep = workout_set.workout_reps.create!(weight: 100, reps: 10)
    @user.personal_records.create!(
      exercise: @bench_press,
      workout: workout,
      workout_rep: rep,
      pr_type: :max_weight,
      weight: 150,
      reps: 5,
      achieved_on: 1.week.ago
    )

    new_workout = create_completed_strength_workout(started_at: 30.minutes.ago)
    new_set =
      new_workout.workout_sets.create!(
        exercise: @bench_press,
        started_at: 30.minutes.ago
      )
    new_set.workout_reps.create!(weight: 100, reps: 10)

    prs = PersonalRecordDetector.new(workout: new_workout).call
    assert prs.none?(&:max_weight?)
  end

  test "creates PR if weight beats existing PR" do
    workout = create_completed_strength_workout
    workout_set =
      workout.workout_sets.create!(
        exercise: @bench_press,
        started_at: 1.hour.ago
      )
    existing_rep = workout_set.workout_reps.create!(weight: 100, reps: 10)
    @user.personal_records.create!(
      exercise: @bench_press,
      workout: workout,
      workout_rep: existing_rep,
      pr_type: :max_weight,
      weight: 100,
      reps: 10,
      achieved_on: 1.week.ago
    )

    new_workout = create_completed_strength_workout(started_at: 30.minutes.ago)
    new_set =
      new_workout.workout_sets.create!(
        exercise: @bench_press,
        started_at: 30.minutes.ago
      )
    new_set.workout_reps.create!(weight: 110, reps: 8)

    prs = PersonalRecordDetector.new(workout: new_workout).call
    weight_pr = prs.find(&:max_weight?)
    assert weight_pr.present?
    assert_equal 110, weight_pr.weight
  end

  test "creates max_reps PR for bodyweight exercises" do
    workout = create_completed_strength_workout
    workout_set =
      workout.workout_sets.create!(exercise: @pull_up, started_at: 1.hour.ago)
    workout_set.workout_reps.create!(reps: 15)

    prs = PersonalRecordDetector.new(workout: workout).call

    assert_equal 1, prs.count
    assert prs.first.max_reps?
    assert_equal 15, prs.first.reps
  end

  test "does not create max_reps PR if reps are below existing PR" do
    workout = create_completed_strength_workout
    workout_set =
      workout.workout_sets.create!(exercise: @pull_up, started_at: 1.hour.ago)
    existing_rep = workout_set.workout_reps.create!(reps: 20)
    @user.personal_records.create!(
      exercise: @pull_up,
      workout: workout,
      workout_rep: existing_rep,
      pr_type: :max_reps,
      reps: 20,
      achieved_on: 1.week.ago
    )

    new_workout = create_completed_strength_workout(started_at: 30.minutes.ago)
    new_set =
      new_workout.workout_sets.create!(
        exercise: @pull_up,
        started_at: 30.minutes.ago
      )
    new_set.workout_reps.create!(reps: 15)

    prs = PersonalRecordDetector.new(workout: new_workout).call
    assert prs.empty?
  end

  test "tracks PRs separately per band type" do
    workout = create_completed_strength_workout
    workout_set =
      workout.workout_sets.create!(
        exercise: @banded_squat,
        started_at: 1.hour.ago
      )
    workout_set.workout_reps.create!(reps: 15, band: "light")
    workout_set.workout_reps.create!(reps: 12, band: "heavy")

    prs = PersonalRecordDetector.new(workout: workout).call

    assert_equal 2, prs.count
    bands = prs.map(&:band).sort
    assert_equal %w[heavy light], bands
  end

  test "does not beat PR with different band" do
    workout = create_completed_strength_workout
    workout_set =
      workout.workout_sets.create!(
        exercise: @banded_squat,
        started_at: 1.hour.ago
      )
    existing_rep = workout_set.workout_reps.create!(reps: 20, band: "light")
    @user.personal_records.create!(
      exercise: @banded_squat,
      workout: workout,
      workout_rep: existing_rep,
      pr_type: :max_reps,
      reps: 20,
      band: "light",
      achieved_on: 1.week.ago
    )

    new_workout = create_completed_strength_workout(started_at: 30.minutes.ago)
    new_set =
      new_workout.workout_sets.create!(
        exercise: @banded_squat,
        started_at: 30.minutes.ago
      )
    new_set.workout_reps.create!(reps: 25, band: "heavy")

    prs = PersonalRecordDetector.new(workout: new_workout).call
    assert_equal 1, prs.count
    assert_equal "heavy", prs.first.band
  end

  test "detects PRs across all reps in workout" do
    workout = create_completed_strength_workout
    set1 =
      workout.workout_sets.create!(
        exercise: @bench_press,
        started_at: 1.hour.ago
      )
    set1.workout_reps.create!(weight: 80, reps: 10)
    set2 =
      workout.workout_sets.create!(
        exercise: @bench_press,
        started_at: 50.minutes.ago
      )
    set2.workout_reps.create!(weight: 100, reps: 5)

    prs = PersonalRecordDetector.new(workout: workout).call

    weight_pr = prs.find(&:max_weight?)
    assert_equal 100, weight_pr.weight

    volume_pr = prs.find(&:max_volume?)
    assert_equal 800, volume_pr.volume
  end

  test "creates longest_distance PR for first run" do
    @user.personal_records.destroy_all
    workout = create_run_workout(distance: 5000, duration: 30.minutes)

    prs = PersonalRecordDetector.new(workout: workout).call

    distance_pr = prs.find(&:longest_distance?)
    assert distance_pr.present?
    assert_equal 5000, distance_pr.distance
  end

  test "creates fastest_pace PR for first run" do
    @user.personal_records.destroy_all
    workout = create_run_workout(distance: 5000, duration: 30.minutes)

    prs = PersonalRecordDetector.new(workout: workout).call

    pace_pr = prs.find(&:fastest_pace?)
    assert pace_pr.present?
    assert_equal 360.0, pace_pr.pace
  end

  test "creates longest_distance PR when beating previous record" do
    @user.personal_records.destroy_all
    previous_run =
      create_run_workout(
        distance: 4000,
        duration: 25.minutes,
        started_at: 1.week.ago
      )
    @user.personal_records.create!(
      workout: previous_run,
      pr_type: :longest_distance,
      distance: 4000,
      achieved_on: 1.week.ago.to_date
    )

    workout = create_run_workout(distance: 5000, duration: 30.minutes)
    prs = PersonalRecordDetector.new(workout: workout).call

    distance_pr = prs.find(&:longest_distance?)
    assert distance_pr.present?
    assert_equal 5000, distance_pr.distance
  end

  test "does not create longest_distance PR when below previous record" do
    @user.personal_records.destroy_all
    previous_run =
      create_run_workout(
        distance: 10_000,
        duration: 40.minutes,
        started_at: 1.week.ago
      )
    @user.personal_records.create!(
      workout: previous_run,
      pr_type: :longest_distance,
      distance: 10_000,
      achieved_on: 1.week.ago.to_date
    )

    workout = create_run_workout(distance: 5000, duration: 30.minutes)
    prs = PersonalRecordDetector.new(workout: workout).call

    assert prs.none?(&:longest_distance?)
  end

  test "creates fastest_pace PR when beating previous record" do
    @user.personal_records.destroy_all
    previous_run =
      create_run_workout(
        distance: 5000,
        duration: 35.minutes,
        started_at: 1.week.ago
      )
    @user.personal_records.create!(
      workout: previous_run,
      pr_type: :fastest_pace,
      distance: 5000,
      pace: 420.0,
      achieved_on: 1.week.ago.to_date
    )

    workout = create_run_workout(distance: 5000, duration: 30.minutes)
    prs = PersonalRecordDetector.new(workout: workout).call

    pace_pr = prs.find(&:fastest_pace?)
    assert pace_pr.present?
    assert_equal 360.0, pace_pr.pace
  end

  test "does not create fastest_pace PR when slower than previous record" do
    @user.personal_records.destroy_all
    previous_run =
      create_run_workout(
        distance: 5000,
        duration: 25.minutes,
        started_at: 1.week.ago
      )
    @user.personal_records.create!(
      workout: previous_run,
      pr_type: :fastest_pace,
      distance: 5000,
      pace: 300.0,
      achieved_on: 1.week.ago.to_date
    )

    workout = create_run_workout(distance: 5000, duration: 30.minutes)
    prs = PersonalRecordDetector.new(workout: workout).call

    assert prs.none?(&:fastest_pace?)
  end

  test "does not create any PRs when distance is zero" do
    @user.personal_records.destroy_all
    workout = create_run_workout(distance: 0, duration: 30.minutes)
    prs = PersonalRecordDetector.new(workout: workout).call
    assert prs.empty?
  end

  test "does not create any PRs for incomplete workout" do
    workout =
      @user.workouts.create!(workout_type: :strength, started_at: 1.hour.ago)
    set =
      workout.workout_sets.create!(
        exercise: @bench_press,
        started_at: 1.hour.ago
      )
    set.workout_reps.create!(weight: 100, reps: 10)

    prs = PersonalRecordDetector.new(workout: workout).call
    assert prs.empty?
  end

  test "does not create max_weight or max_volume PR with zero weight" do
    workout = create_completed_strength_workout
    set =
      workout.workout_sets.create!(
        exercise: @bench_press,
        started_at: 1.hour.ago
      )
    set.workout_reps.create!(weight: 0, reps: 10)

    prs = PersonalRecordDetector.new(workout: workout).call
    assert prs.none?(&:max_weight?)
    assert prs.none?(&:max_volume?)
  end

  private

  def create_completed_strength_workout(started_at: 1.hour.ago)
    @user.workouts.create!(
      workout_type: :strength,
      started_at: started_at,
      ended_at: Time.current
    )
  end

  def create_run_workout(distance:, duration:, started_at: 1.hour.ago)
    @user.workouts.create!(
      workout_type: :run,
      started_at: started_at,
      ended_at: started_at + duration,
      distance: distance
    )
  end
end
