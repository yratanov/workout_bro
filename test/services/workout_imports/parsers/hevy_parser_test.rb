require "test_helper"

class WorkoutImports::Parsers::HevyParserTest < ActiveSupport::TestCase
  test "imports workouts grouped by date" do
    result = build_parser(valid_hevy_csv).parse
    assert_equal 2, result[:imported]
  end

  test "creates workout sets for each exercise" do
    build_parser(valid_hevy_csv).parse
    jan15_workout = find_workout_by_date("2024-01-15")
    assert_equal 2, jan15_workout.workout_sets.count
  end

  test "creates workout reps with correct weight from weight_kg" do
    build_parser(valid_hevy_csv).parse
    jan15_workout = find_workout_by_date("2024-01-15")
    squat_set =
      jan15_workout
        .workout_sets
        .joins(:exercise)
        .where(exercises: { name: "Squat" })
        .first

    assert_equal 2, squat_set.workout_reps.count
    weights = squat_set.workout_reps.map(&:weight).sort
    assert_equal [100.0, 110.0], weights
  end

  test "parses ISO 8601 datetime correctly" do
    csv = <<~CSV
      title,start_time,end_time,exercise_title,weight_kg,reps
      Morning,2024-01-15T08:30:00+02:00,2024-01-15T09:30:00+02:00,Deadlift,140,5
    CSV

    result = build_parser(csv).parse
    assert_equal 1, result[:imported]
  end

  test "imports with nil weight when weight is missing" do
    csv = <<~CSV
      title,start_time,end_time,exercise_title,weight_kg,reps
      Morning,2024-01-15T08:00:00Z,2024-01-15T09:00:00Z,Pull-Up,,15
    CSV

    result = build_parser(csv).parse
    assert_equal 1, result[:imported]

    workout = find_workout_by_date("2024-01-15")
    workout_rep = workout.workout_sets.first.workout_reps.first
    assert_nil workout_rep.weight
    assert_equal 15, workout_rep.reps
  end

  test "skips rows with invalid datetime" do
    csv = <<~CSV
      title,start_time,end_time,exercise_title,weight_kg,reps
      Morning,not-a-date,not-a-date,Squat,100,10
    CSV

    result = build_parser(csv).parse
    assert_equal 0, result[:imported]
  end

  private

  def valid_hevy_csv
    <<~CSV
      title,start_time,end_time,exercise_title,weight_kg,reps,set_order
      Leg Day,2024-01-15T08:00:00Z,2024-01-15T09:00:00Z,Squat,100,10,1
      Leg Day,2024-01-15T08:00:00Z,2024-01-15T09:00:00Z,Squat,110,8,2
      Leg Day,2024-01-15T08:00:00Z,2024-01-15T09:00:00Z,Leg Press,200,12,1
      Push Day,2024-01-17T10:00:00Z,2024-01-17T11:00:00Z,Bench Press,60,10,1
    CSV
  end

  def find_workout_by_date(date_str)
    users(:john)
      .workouts
      .where(workout_import: workout_imports(:pending_import))
      .find { |w| w.started_at.to_date == Date.parse(date_str) }
  end

  def build_parser(csv_content)
    WorkoutImports::Parsers::HevyParser.new(
      csv_content: csv_content,
      user: users(:john),
      workout_import: workout_imports(:pending_import),
      exercise_matcher: WorkoutImports::ExerciseMatcher.new(user: users(:john))
    )
  end
end
