require "test_helper"

class WorkoutExporterTest < ActiveSupport::TestCase
  test "returns valid CSV" do
    result = WorkoutExporter.new(user: users(:john)).call
    assert_instance_of String, result
    assert_nothing_raised { CSV.parse(result) }
  end

  test "includes CSV headers" do
    result = WorkoutExporter.new(user: users(:john)).call
    headers = CSV.parse(result).first
    assert_equal WorkoutExporter::HEADERS, headers
  end

  test "includes strength workout data" do
    result = WorkoutExporter.new(user: users(:john)).call
    csv = CSV.parse(result, headers: true)

    strength_rows = csv.select { |row| row["workout_type"] == "strength" }
    refute strength_rows.empty?

    first_strength_row = strength_rows.first
    assert_equal "Bench Press", first_strength_row["exercise_name"]
    assert_equal "chest", first_strength_row["muscle_group"]
  end

  test "includes run workout data" do
    result = WorkoutExporter.new(user: users(:john)).call
    csv = CSV.parse(result, headers: true)

    run_rows = csv.select { |row| row["workout_type"] == "run" }
    refute run_rows.empty?

    run_row = run_rows.first
    assert_equal "5000", run_row["distance_meters"]
    assert_equal "1800", run_row["time_seconds"]
    assert_equal "6:00", run_row["pace_per_km"]
  end

  test "includes garmin metrics for run workouts" do
    workouts(:run_workout).update!(
      avg_heart_rate: 155,
      max_heart_rate: 178,
      avg_cadence: 170,
      elevation_gain: 120.5,
      vo2max: 48.3
    )

    result = WorkoutExporter.new(user: users(:john)).call
    csv = CSV.parse(result, headers: true)

    run_row = csv.find { |row| row["workout_type"] == "run" }
    assert_equal "155", run_row["avg_heart_rate"]
    assert_equal "178", run_row["max_heart_rate"]
    assert_equal "170", run_row["avg_cadence"]
    assert_equal "120.5", run_row["elevation_gain"]
    assert_equal "48.3", run_row["vo2max"]
  end

  test "has nil garmin metrics for strength workouts" do
    result = WorkoutExporter.new(user: users(:john)).call
    csv = CSV.parse(result, headers: true)

    strength_row = csv.find { |row| row["workout_type"] == "strength" }
    assert_nil strength_row["avg_heart_rate"]
    assert_nil strength_row["max_heart_rate"]
    assert_nil strength_row["avg_cadence"]
    assert_nil strength_row["elevation_gain"]
    assert_nil strength_row["vo2max"]
  end

  test "excludes incomplete workouts" do
    result = WorkoutExporter.new(user: users(:john)).call
    csv = CSV.parse(result, headers: true)
    assert csv.size > 0
  end

  test "includes weight unit from user settings" do
    user = users(:john)
    result = WorkoutExporter.new(user: user).call
    csv = CSV.parse(result, headers: true)

    strength_rows = csv.select { |row| row["workout_type"] == "strength" }
    strength_rows.each do |row|
      assert_equal user.weight_unit, row["weight_unit"]
    end
  end

  test "formats pace correctly" do
    result = WorkoutExporter.new(user: users(:john)).call
    csv = CSV.parse(result, headers: true)

    run_row = csv.find { |row| row["workout_type"] == "run" }
    assert_equal "6:00", run_row["pace_per_km"]
  end

  test "handles empty data gracefully" do
    new_user =
      User.create!(
        email: "empty@example.com",
        password: "password",
        setup_completed: true
      )

    result = WorkoutExporter.new(user: new_user).call
    csv = CSV.parse(result, headers: true)
    assert_equal 0, csv.count
  end

  test "orders workouts by start time ascending" do
    result = WorkoutExporter.new(user: users(:john)).call
    csv = CSV.parse(result, headers: true)

    dates = csv.map { |row| row["date"] }
    assert_equal dates.sort, dates
  end

  test "includes workout and set notes" do
    workouts(:completed_workout).update!(notes: "Great session!")
    workout_sets(:completed_set).update!(notes: "Felt strong")

    result = WorkoutExporter.new(user: users(:john)).call
    csv = CSV.parse(result, headers: true)

    strength_row =
      csv.find do |row|
        row["workout_type"] == "strength" && row["workout_notes"].present?
      end
    assert_equal "Great session!", strength_row["workout_notes"]
    assert_equal "Felt strong", strength_row["set_notes"]
  end

  test "includes band information" do
    workout_reps(:rep_one).update!(band: "medium")

    result = WorkoutExporter.new(user: users(:john)).call
    csv = CSV.parse(result, headers: true)

    row_with_band = csv.find { |row| row["band"].present? }
    assert_equal "medium", row_with_band["band"]
  end
end
