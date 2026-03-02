require "test_helper"

class AiWorkoutPromptHelpersTest < ActiveSupport::TestCase
  # Include the concern in a test class to access private methods
  class TestHelper
    include AiWorkoutPromptHelpers

    # Expose private methods for testing
    public :format_duration,
           :format_pace,
           :format_run_summary,
           :format_workout_exercises
  end

  setup { @helper = TestHelper.new }

  # format_duration tests

  test "format_duration converts seconds to Xm Ys format" do
    assert_equal "5m 30s", @helper.format_duration(330)
  end

  test "format_duration returns N/A for nil" do
    assert_equal "N/A", @helper.format_duration(nil)
  end

  test "format_duration returns N/A for zero" do
    assert_equal "N/A", @helper.format_duration(0)
  end

  test "format_duration returns N/A for negative" do
    assert_equal "N/A", @helper.format_duration(-10)
  end

  test "format_duration handles exact minutes" do
    assert_equal "2m 0s", @helper.format_duration(120)
  end

  # format_pace tests

  test "format_pace converts seconds per km to MM:SS min/km" do
    assert_equal "5:30 min/km", @helper.format_pace(330)
  end

  test "format_pace pads seconds with leading zero" do
    assert_equal "5:05 min/km", @helper.format_pace(305)
  end

  test "format_pace returns N/A for nil" do
    assert_equal "N/A", @helper.format_pace(nil)
  end

  test "format_pace returns N/A for zero" do
    assert_equal "N/A", @helper.format_pace(0)
  end

  test "format_pace returns N/A for negative" do
    assert_equal "N/A", @helper.format_pace(-60)
  end

  # format_run_summary tests

  test "format_run_summary includes distance pace and duration" do
    workout = workouts(:run_workout)
    result = @helper.format_run_summary(workout)

    assert_includes result, "Type: Run"
    assert_includes result, "Distance:"
    assert_includes result, "Duration:"
  end

  test "format_run_summary includes optional Garmin metrics when present" do
    workout = workouts(:run_workout)
    workout.avg_heart_rate = 155
    workout.max_heart_rate = 180
    workout.avg_cadence = 170
    workout.elevation_gain = 120.5
    workout.vo2max = 45.3

    result = @helper.format_run_summary(workout)

    assert_includes result, "Avg Heart Rate: 155 bpm"
    assert_includes result, "Max Heart Rate: 180 bpm"
    assert_includes result, "Avg Cadence: 170 spm"
    assert_includes result, "Elevation Gain: 120.5m"
    assert_includes result, "VO2max: 45.3"
  end

  test "format_run_summary omits Garmin metrics when absent" do
    workout = workouts(:run_workout)
    workout.avg_heart_rate = nil
    workout.max_heart_rate = nil
    workout.avg_cadence = nil
    workout.elevation_gain = nil
    workout.vo2max = nil

    result = @helper.format_run_summary(workout)

    refute_includes result, "Avg Heart Rate"
    refute_includes result, "Max Heart Rate"
    refute_includes result, "Avg Cadence"
    refute_includes result, "Elevation Gain"
    refute_includes result, "VO2max"
  end

  test "format_run_summary includes notes when present" do
    workout = workouts(:run_workout)
    workout.notes = "Felt great today"

    result = @helper.format_run_summary(workout)

    assert_includes result, "Notes: Felt great today"
  end

  # format_workout_exercises tests

  test "format_workout_exercises formats exercise data with reps and weight" do
    user = users(:john)
    workout = workouts(:completed_workout)
    workout_sets = workout.workout_sets

    lines = @helper.format_workout_exercises(workout_sets, user)

    assert lines.any?, "Expected formatted exercise lines"
    exercise_line = lines.find { |l| l.include?("Bench Press") }
    assert exercise_line.present?, "Expected Bench Press in output"
    assert_match(/\d+kg x \d+/, exercise_line)
  end
end
