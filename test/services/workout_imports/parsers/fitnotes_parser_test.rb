require "test_helper"

class WorkoutImports::Parsers::FitnotesParserTest < ActiveSupport::TestCase
  test "imports workouts grouped by date with valid FitNotes format kg" do
    result = build_parser(fitnotes_kg_csv).parse
    assert_equal 2, result[:imported]
  end

  test "creates workout sets for each exercise" do
    build_parser(fitnotes_kg_csv).parse
    jan15_workout = find_workout_by_date("2024-01-15")
    assert_equal 2, jan15_workout.workout_sets.count
  end

  test "creates workout reps with correct weight" do
    build_parser(fitnotes_kg_csv).parse
    jan15_workout = find_workout_by_date("2024-01-15")
    bench_set =
      jan15_workout
        .workout_sets
        .joins(:exercise)
        .where(exercises: { name: "Bench Press" })
        .first

    assert_equal 2, bench_set.workout_reps.count
    weights = bench_set.workout_reps.map(&:weight).sort
    assert_equal [60.0, 70.0], weights
  end

  test "converts pounds to kilograms" do
    csv = <<~CSV
      Date,Exercise,Category,Weight (lbs),Reps
      2024-01-15,Bench Press,Chest,132,10
    CSV

    build_parser(csv).parse
    workout = find_workout_by_date("2024-01-15")
    workout_rep = workout.workout_sets.first.workout_reps.first
    assert_in_delta 59.87, workout_rep.weight, 0.1
  end

  test "parses generic weight column" do
    csv = <<~CSV
      Date,Exercise,Category,Weight,Reps
      2024-01-15,Bench Press,Chest,60,10
    CSV

    result = build_parser(csv).parse
    assert_equal 1, result[:imported]

    workout = find_workout_by_date("2024-01-15")
    workout_rep = workout.workout_sets.first.workout_reps.first
    assert_equal 60.0, workout_rep.weight
  end

  test "imports with nil weight when weight is missing" do
    csv = <<~CSV
      Date,Exercise,Category,Weight (kg),Reps
      2024-01-15,Pull-Up,Back,,15
    CSV

    result = build_parser(csv).parse
    assert_equal 1, result[:imported]

    workout = find_workout_by_date("2024-01-15")
    workout_rep = workout.workout_sets.first.workout_reps.first
    assert_nil workout_rep.weight
    assert_equal 15, workout_rep.reps
  end

  test "skips rows with invalid dates" do
    csv = <<~CSV
      Date,Exercise,Category,Weight (kg),Reps
      invalid,Bench Press,Chest,60,10
    CSV

    result = build_parser(csv).parse
    assert_equal 0, result[:imported]
  end

  test "skips rows with zero reps" do
    csv = <<~CSV
      Date,Exercise,Category,Weight (kg),Reps
      2024-01-15,Bench Press,Chest,60,0
    CSV

    result = build_parser(csv).parse
    assert_equal 0, result[:imported]
  end

  test "skips rows with missing exercise name" do
    csv = <<~CSV
      Date,Exercise,Category,Weight (kg),Reps
      2024-01-15,,Chest,60,10
    CSV

    result = build_parser(csv).parse
    assert_equal 0, result[:imported]
  end

  private

  def fitnotes_kg_csv
    <<~CSV
      Date,Exercise,Category,Weight (kg),Reps,Notes
      2024-01-15,Bench Press,Chest,60,10,
      2024-01-15,Bench Press,Chest,70,8,
      2024-01-15,Squat,Legs,100,5,
      2024-01-17,Deadlift,Back,120,3,
    CSV
  end

  def find_workout_by_date(date_str)
    users(:john)
      .workouts
      .where(workout_import: workout_imports(:pending_import))
      .find { |w| w.started_at.to_date == Date.parse(date_str) }
  end

  def build_parser(csv_content)
    WorkoutImports::Parsers::FitnotesParser.new(
      csv_content: csv_content,
      user: users(:john),
      workout_import: workout_imports(:pending_import),
      exercise_matcher: WorkoutImports::ExerciseMatcher.new(user: users(:john))
    )
  end
end
