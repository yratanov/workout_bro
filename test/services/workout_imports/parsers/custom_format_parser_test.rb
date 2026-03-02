require "test_helper"

class WorkoutImports::Parsers::CustomFormatParserTest < ActiveSupport::TestCase
  test "imports multiple workouts with standard format" do
    result = build_parser(standard_csv).parse
    assert_equal 2, result[:imported]
  end

  test "creates workout records" do
    build_parser(standard_csv).parse
    workouts =
      users(:john).workouts.where(
        workout_import: workout_imports(:pending_import)
      )
    assert_equal 2, workouts.count
  end

  test "creates workout sets for each exercise" do
    build_parser(standard_csv).parse
    workout =
      users(:john)
        .workouts
        .where(workout_import: workout_imports(:pending_import))
        .first
    assert_equal 2, workout.workout_sets.count
  end

  test "creates workout reps with correct weight and reps" do
    build_parser(standard_csv).parse
    workout =
      users(:john)
        .workouts
        .where(workout_import: workout_imports(:pending_import))
        .order(:started_at)
        .first
    bench_set =
      workout
        .workout_sets
        .joins(:exercise)
        .where(exercises: { name: "Bench Press" })
        .first

    assert_equal 2, bench_set.workout_reps.count
    assert_equal 60.0, bench_set.workout_reps.first.weight
    assert_equal 10, bench_set.workout_reps.first.reps
  end

  test "parses Cyrillic x correctly" do
    csv = <<~CSV
      2024-01-15,,,,
      Deadlift,100х8,110х6,,
    CSV

    result = build_parser(csv).parse
    assert_equal 1, result[:imported]

    workout =
      users(:john)
        .workouts
        .where(workout_import: workout_imports(:pending_import))
        .first
    workout_set = workout.workout_sets.first
    assert_equal 100.0, workout_set.workout_reps.first.weight
    assert_equal 8, workout_set.workout_reps.first.reps
  end

  test "parses reps without weight for bodyweight exercises" do
    csv = <<~CSV
      2024-01-15,,,,
      Pull-Up,15,12,10,
    CSV

    result = build_parser(csv).parse
    assert_equal 1, result[:imported]

    workout =
      users(:john)
        .workouts
        .where(workout_import: workout_imports(:pending_import))
        .first
    workout_set = workout.workout_sets.first
    assert_equal 3, workout_set.workout_reps.count
    assert_nil workout_set.workout_reps.first.weight
    assert_equal 15, workout_set.workout_reps.first.reps
  end

  test "handles empty lines between workouts" do
    csv = <<~CSV
      2024-01-15,,,,
      Bench Press,60x10,,
      2024-01-16,,,,
      Squat,100x5,,
    CSV

    result = build_parser(csv).parse
    assert_equal 2, result[:imported]
  end

  test "creates new exercises for the user" do
    csv = <<~CSV
      2024-01-15,,,,
      New Exercise,50x10,,
    CSV

    assert_difference -> { users(:john).exercises.count }, 1 do
      build_parser(csv).parse
    end
    assert users(:john).exercises.find_by(name: "New Exercise").present?
  end

  test "matches existing exercises case-insensitively" do
    csv = <<~CSV
      2024-01-15,,,,
      bench press,60x10,,
    CSV

    assert_no_difference -> { users(:john).exercises.count } do
      build_parser(csv).parse
    end
  end

  test "does not create workout for empty date" do
    csv = <<~CSV
      2024-01-15,,,,
    CSV

    result = build_parser(csv).parse
    assert_equal 0, result[:imported]
  end

  test "skips workouts for dates that already have a workout" do
    user = users(:john)
    user.workouts.create!(
      workout_type: :strength,
      started_at: Date.parse("2024-01-15").to_datetime.change(hour: 10),
      ended_at: Date.parse("2024-01-15").to_datetime.change(hour: 11)
    )

    result = build_parser(standard_csv).parse
    assert_equal 1, result[:imported]
    assert_equal 1, result[:skipped]
  end

  test "only creates workout for the new date when duplicate exists" do
    user = users(:john)
    user.workouts.create!(
      workout_type: :strength,
      started_at: Date.parse("2024-01-15").to_datetime.change(hour: 10),
      ended_at: Date.parse("2024-01-15").to_datetime.change(hour: 11)
    )

    build_parser(standard_csv).parse
    imported_workouts =
      user.workouts.where(workout_import: workout_imports(:pending_import))
    assert_equal 1, imported_workouts.count
    assert_equal Date.parse("2024-01-17"),
                 imported_workouts.first.started_at.to_date
  end

  test "does not create duplicate workouts on re-import" do
    user = users(:john)
    user.workouts.create!(
      workout_type: :strength,
      started_at: Date.parse("2024-01-15").to_datetime.change(hour: 10),
      ended_at: Date.parse("2024-01-15").to_datetime.change(hour: 11)
    )

    build_parser(standard_csv).parse

    second_parser =
      WorkoutImports::Parsers::CustomFormatParser.new(
        csv_content: standard_csv,
        user: user,
        workout_import: workout_imports(:second_import),
        exercise_matcher: WorkoutImports::ExerciseMatcher.new(user: user)
      )

    result = second_parser.parse
    assert_equal 0, result[:imported]
    assert_equal 2, result[:skipped]
  end

  private

  def standard_csv
    <<~CSV
      2024-01-15,,,,
      Bench Press,60x10,70x8,,
      Squat,100x5,110x5,,

      2024-01-17,,,,
      Deadlift,120x3,130x3,,
    CSV
  end

  def build_parser(csv_content)
    WorkoutImports::Parsers::CustomFormatParser.new(
      csv_content: csv_content,
      user: users(:john),
      workout_import: workout_imports(:pending_import),
      exercise_matcher: WorkoutImports::ExerciseMatcher.new(user: users(:john))
    )
  end
end
