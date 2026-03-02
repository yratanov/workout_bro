require "test_helper"

# == Schema Information
#
# Table name: personal_records
# Database name: primary
#
#  id             :integer          not null, primary key
#  achieved_on    :date             not null
#  band           :string
#  distance       :integer
#  pace           :float
#  pr_type        :integer          default("max_weight"), not null
#  reps           :integer
#  volume         :float
#  weight         :float
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  exercise_id    :integer
#  user_id        :integer          not null
#  workout_id     :integer          not null
#  workout_rep_id :integer
#
# Indexes
#
#  index_personal_records_on_exercise_id     (exercise_id)
#  index_personal_records_on_workout_id      (workout_id)
#  index_personal_records_on_workout_rep_id  (workout_rep_id)
#  index_prs_on_user_exercise_type_band      (user_id,exercise_id,pr_type,band)
#
# Foreign Keys
#
#  exercise_id     (exercise_id => exercises.id)
#  user_id         (user_id => users.id)
#  workout_id      (workout_id => workouts.id)
#  workout_rep_id  (workout_rep_id => workout_reps.id)
#

class PersonalRecordTest < ActiveSupport::TestCase
  test "belongs to user" do
    pr = personal_records(:bench_press_max_weight)
    assert_equal users(:john), pr.user
  end

  test "belongs to exercise" do
    pr = personal_records(:bench_press_max_weight)
    assert_equal exercises(:bench_press), pr.exercise
  end

  test "belongs to workout" do
    pr = personal_records(:bench_press_max_weight)
    assert_equal workouts(:completed_workout), pr.workout
  end

  test "belongs to workout_rep" do
    pr = personal_records(:bench_press_max_weight)
    assert_equal workout_reps(:rep_two), pr.workout_rep
  end

  test "is valid with valid strength PR attributes" do
    pr =
      PersonalRecord.new(
        user: users(:john),
        exercise: exercises(:bench_press),
        workout: workouts(:completed_workout),
        workout_rep: workout_reps(:rep_without_pr),
        pr_type: :max_weight,
        weight: 100,
        reps: 10,
        achieved_on: Date.today
      )
    assert pr.valid?
  end

  test "is valid with valid run PR attributes" do
    run_workout =
      users(:john).workouts.create!(
        workout_type: :run,
        started_at: 1.hour.ago,
        ended_at: Time.current,
        distance: 5000,
        time_in_seconds: 1800
      )
    pr =
      PersonalRecord.new(
        user: users(:john),
        workout: run_workout,
        pr_type: :longest_distance,
        distance: 5000,
        achieved_on: Date.today
      )
    assert pr.valid?
  end

  test "requires pr_type" do
    pr = PersonalRecord.new(pr_type: nil)
    assert_not pr.valid?
    assert pr.errors[:pr_type].present?
  end

  test "requires reps for strength PRs" do
    pr = PersonalRecord.new(pr_type: :max_weight, reps: nil)
    assert_not pr.valid?
    assert pr.errors[:reps].present?
  end

  test "requires positive reps for strength PRs" do
    pr = PersonalRecord.new(pr_type: :max_weight, reps: 0)
    assert_not pr.valid?
    assert pr.errors[:reps].present?
  end

  test "does not require reps for run PRs" do
    run_workout =
      users(:john).workouts.create!(
        workout_type: :run,
        started_at: 1.hour.ago,
        ended_at: Time.current,
        distance: 5000,
        time_in_seconds: 1800
      )
    pr =
      PersonalRecord.new(
        user: users(:john),
        workout: run_workout,
        pr_type: :longest_distance,
        distance: 5000,
        achieved_on: Date.today
      )
    assert pr.valid?
  end

  test "requires distance for run PRs" do
    pr = PersonalRecord.new(pr_type: :longest_distance, distance: nil)
    assert_not pr.valid?
    assert pr.errors[:distance].present?
  end

  test "requires pace for fastest_pace PRs" do
    pr = PersonalRecord.new(pr_type: :fastest_pace, distance: 5000, pace: nil)
    assert_not pr.valid?
    assert pr.errors[:pace].present?
  end

  test "requires achieved_on" do
    pr = PersonalRecord.new(achieved_on: nil)
    assert_not pr.valid?
    assert pr.errors[:achieved_on].present?
  end

  test "validates band is in allowed values" do
    pr =
      PersonalRecord.new(
        user: users(:john),
        exercise: exercises(:bench_press),
        workout: workouts(:completed_workout),
        workout_rep: workout_reps(:rep_without_pr),
        pr_type: :max_weight,
        weight: 100,
        reps: 10,
        achieved_on: Date.today,
        band: "invalid_band"
      )
    assert_not pr.valid?
    assert pr.errors[:band].present?
  end

  test "allows nil band" do
    pr =
      PersonalRecord.new(
        user: users(:john),
        exercise: exercises(:bench_press),
        workout: workouts(:completed_workout),
        workout_rep: workout_reps(:rep_without_pr),
        pr_type: :max_weight,
        weight: 100,
        reps: 10,
        achieved_on: Date.today,
        band: nil
      )
    assert pr.valid?
  end

  test "allows valid band values" do
    WorkoutRep::BANDS.each do |band|
      pr =
        PersonalRecord.new(
          user: users(:john),
          exercise: exercises(:bench_press),
          workout: workouts(:completed_workout),
          workout_rep: workout_reps(:rep_without_pr),
          pr_type: :max_weight,
          weight: 100,
          reps: 10,
          achieved_on: Date.today,
          band: band
        )
      assert pr.valid?, "Expected band '#{band}' to be valid"
    end
  end

  test "defines pr_type enum" do
    assert_equal(
      {
        "max_weight" => 0,
        "max_volume" => 1,
        "max_reps" => 2,
        "longest_distance" => 3,
        "fastest_pace" => 4
      },
      PersonalRecord.pr_types
    )
  end

  test "allows max_weight type" do
    pr = personal_records(:bench_press_max_weight)
    assert pr.max_weight?
  end

  test "allows max_volume type" do
    pr = personal_records(:bench_press_max_volume)
    assert pr.max_volume?
  end

  test "allows longest_distance type" do
    run_workout =
      users(:john).workouts.create!(
        workout_type: :run,
        started_at: 1.hour.ago,
        ended_at: Time.current,
        distance: 5000,
        time_in_seconds: 1800
      )
    pr =
      PersonalRecord.create!(
        user: users(:john),
        workout: run_workout,
        pr_type: :longest_distance,
        distance: 5000,
        achieved_on: Date.today
      )
    assert pr.longest_distance?
  end

  test "allows fastest_pace type" do
    run_workout =
      users(:john).workouts.create!(
        workout_type: :run,
        started_at: 1.hour.ago,
        ended_at: Time.current,
        distance: 5000,
        time_in_seconds: 1800
      )
    pr =
      PersonalRecord.create!(
        user: users(:john),
        workout: run_workout,
        pr_type: :fastest_pace,
        distance: 5000,
        pace: 6.0,
        achieved_on: Date.today
      )
    assert pr.fastest_pace?
  end

  test "recent_first scope orders by created_at desc" do
    newer_pr =
      PersonalRecord.create!(
        user: users(:john),
        exercise: exercises(:squat),
        workout: workouts(:completed_workout),
        workout_rep: workout_reps(:rep_without_pr),
        pr_type: :max_weight,
        weight: 150,
        reps: 5,
        achieved_on: Date.today
      )

    assert_equal newer_pr, PersonalRecord.recent_first.first
  end

  test "timeline scope includes exercise" do
    records = PersonalRecord.timeline
    assert records.first.association(:exercise).loaded?
  end
end
