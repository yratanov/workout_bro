require "test_helper"

class WorkoutsHelperTest < ActionView::TestCase
  # modal_title tests

  test "modal_title returns Run with date for a run workout" do
    workout = Workout.new(workout_type: :run, created_at: Date.new(2024, 1, 15))
    assert_equal "Run \u00b7 15 Jan 2024", modal_title(workout)
  end

  test "modal_title returns routine day name with date for strength workout with routine day" do
    workout =
      Workout.new(
        workout_type: :strength,
        created_at: Date.new(2024, 1, 15),
        workout_routine_day: workout_routine_days(:push_day)
      )
    assert_equal "Push Day \u00b7 15 Jan 2024", modal_title(workout)
  end

  test "modal_title returns Strength with date for strength workout without routine day" do
    workout =
      Workout.new(
        workout_type: :strength,
        created_at: Date.new(2024, 1, 15),
        workout_routine_day: nil
      )
    assert_equal "Strength \u00b7 15 Jan 2024", modal_title(workout)
  end

  # run_pace tests

  test "run_pace calculates pace correctly for a run workout" do
    started_at = Time.zone.parse("2024-01-15 08:00:00")
    ended_at = Time.zone.parse("2024-01-15 08:30:00")
    workout =
      Workout.new(
        workout_type: :run,
        started_at: started_at,
        ended_at: ended_at,
        distance: 5000
      )
    assert_equal "6:00 min/km", run_pace(workout)
  end

  test "run_pace returns nil for a non-run workout" do
    workout = Workout.new(workout_type: :strength)
    assert_nil run_pace(workout)
  end

  test "run_pace returns nil when started_at is missing" do
    workout =
      Workout.new(workout_type: :run, ended_at: Time.current, distance: 5000)
    assert_nil run_pace(workout)
  end

  test "run_pace returns nil when ended_at is missing" do
    workout =
      Workout.new(workout_type: :run, started_at: Time.current, distance: 5000)
    assert_nil run_pace(workout)
  end

  test "run_pace returns nil when distance is zero" do
    workout =
      Workout.new(
        workout_type: :run,
        started_at: 30.minutes.ago,
        ended_at: Time.current,
        distance: 0
      )
    assert_nil run_pace(workout)
  end

  test "run_pace returns nil when distance is nil" do
    workout =
      Workout.new(
        workout_type: :run,
        started_at: 30.minutes.ago,
        ended_at: Time.current,
        distance: nil
      )
    assert_nil run_pace(workout)
  end

  # format_volume tests

  test "format_volume formats small volumes with unit" do
    assert_equal "500kg", format_volume(500, "kg")
  end

  test "format_volume formats large volumes in tonnes" do
    assert_equal "1.5t", format_volume(1500, "kg")
  end

  test "format_volume formats whole tonnes without decimal" do
    assert_equal "2t", format_volume(2000, "kg")
  end

  test "format_volume handles zero volume" do
    assert_equal "0kg", format_volume(0, "kg")
  end

  test "format_volume handles nil volume" do
    assert_equal "0kg", format_volume(nil, "kg")
  end

  test "format_volume respects user's weight unit" do
    assert_equal "500lbs", format_volume(500, "lbs")
  end

  test "format_volume uses kg as default unit" do
    assert_equal "500kg", format_volume(500)
  end

  test "format_volume rounds decimal volumes" do
    assert_equal "1.2t", format_volume(1234.567, "kg")
  end

  # comparison_class tests

  test "comparison_class returns green class for positive diff" do
    assert_equal "text-green-400", comparison_class(10)
  end

  test "comparison_class returns red class for negative diff" do
    assert_equal "text-red-400", comparison_class(-10)
  end

  test "comparison_class returns slate class for zero diff" do
    assert_equal "text-slate-400", comparison_class(0)
  end

  test "comparison_class returns slate class for nil diff" do
    assert_equal "text-slate-400", comparison_class(nil)
  end

  # comparison_arrow tests

  test "comparison_arrow returns chevron_up for positive diff" do
    assert_equal "chevron_up", comparison_arrow(10)
  end

  test "comparison_arrow returns chevron_down for negative diff" do
    assert_equal "chevron_down", comparison_arrow(-10)
  end

  test "comparison_arrow returns minus for zero diff" do
    assert_equal "minus", comparison_arrow(0)
  end

  test "comparison_arrow returns minus for nil diff" do
    assert_equal "minus", comparison_arrow(nil)
  end

  # format_pace tests

  test "format_pace formats pace in minutes and seconds" do
    assert_equal "6:00", format_pace(360)
  end

  test "format_pace formats pace with single digit seconds" do
    assert_equal "6:05", format_pace(365)
  end

  test "format_pace returns nil for nil pace" do
    assert_nil format_pace(nil)
  end

  test "format_pace returns nil for zero pace" do
    assert_nil format_pace(0)
  end

  test "format_pace returns nil for negative pace" do
    assert_nil format_pace(-10)
  end

  # format_pace_diff tests

  test "format_pace_diff formats small differences in seconds only" do
    assert_equal "15s", format_pace_diff(15)
  end

  test "format_pace_diff formats larger differences in minutes and seconds" do
    assert_equal "1:15", format_pace_diff(75)
  end

  test "format_pace_diff handles negative differences with absolute value" do
    assert_equal "15s", format_pace_diff(-15)
  end

  test "format_pace_diff returns nil for nil input" do
    assert_nil format_pace_diff(nil)
  end

  # pr_type_label tests

  test "pr_type_label returns translated label for max_weight" do
    assert_equal "Max Weight", pr_type_label(:max_weight)
  end

  test "pr_type_label returns translated label for max_volume" do
    assert_equal "Max Volume", pr_type_label(:max_volume)
  end

  test "pr_type_label returns translated label for max_reps" do
    assert_equal "Max Reps", pr_type_label(:max_reps)
  end
end
