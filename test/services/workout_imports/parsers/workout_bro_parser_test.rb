require "test_helper"

class WorkoutImports::Parsers::WorkoutBroParserTest < ActiveSupport::TestCase
  test "imports strength workouts" do
    result = build_parser(strength_csv).parse
    assert_equal 1, result[:imported]
  end

  test "creates workout sets for each exercise" do
    build_parser(strength_csv).parse
    workout = find_workout_by_date("2024-01-20")
    assert_equal 2, workout.workout_sets.count
  end

  test "creates workout reps with correct data" do
    build_parser(strength_csv).parse
    workout = find_workout_by_date("2024-01-20")
    bench_set =
      workout
        .workout_sets
        .joins(:exercise)
        .where(exercises: { name: "Bench Press" })
        .first

    assert_equal 2, bench_set.workout_reps.count
    weights = bench_set.workout_reps.map(&:weight).sort
    assert_equal [60.0, 65.0], weights
  end

  test "imports run workouts" do
    result = build_parser(run_csv).parse
    assert_equal 1, result[:imported]
  end

  test "creates run workout with correct data" do
    build_parser(run_csv).parse
    workout = find_workout_by_date("2024-01-21")

    assert workout.run?
    assert_equal 5000, workout.distance
    assert_equal 1800, workout.time_in_seconds
    assert_equal "Morning run", workout.notes
  end

  test "imports both strength and run workouts" do
    csv = <<~CSV
      date,workout_type,exercise_name,muscle_group,set_number,rep_number,reps,weight,weight_unit,band,distance_meters,time_seconds,pace_per_km,workout_notes,set_notes
      2024-01-22,strength,Bench Press,chest,1,1,10,60,kg,,,,,,
      2024-01-22,run,,,,,,,,,5000,1800,6:00,,
    CSV

    result = build_parser(csv).parse
    assert_equal 2, result[:imported]
  end

  test "imports band information" do
    csv = <<~CSV
      date,workout_type,exercise_name,muscle_group,set_number,rep_number,reps,weight,weight_unit,band,distance_meters,time_seconds,pace_per_km,workout_notes,set_notes
      2024-01-23,strength,Banded Squat,legs,1,1,15,,kg,medium,,,,Felt good,
    CSV

    build_parser(csv).parse
    workout =
      users(:john)
        .workouts
        .where(workout_import: workout_imports(:pending_import))
        .first
    workout_rep = workout.workout_sets.first.workout_reps.first
    assert_equal "medium", workout_rep.band
  end

  test "imports notes" do
    csv = <<~CSV
      date,workout_type,exercise_name,muscle_group,set_number,rep_number,reps,weight,weight_unit,band,distance_meters,time_seconds,pace_per_km,workout_notes,set_notes
      2024-01-24,strength,Bench Press,chest,1,1,10,60,kg,,,,,Great workout,Felt strong
    CSV

    build_parser(csv).parse
    workout =
      users(:john)
        .workouts
        .where(workout_import: workout_imports(:pending_import))
        .first
    assert_equal "Great workout", workout.notes
    assert_equal "Felt strong", workout.workout_sets.first.notes
  end

  test "creates separate sets for multiple sets per exercise" do
    csv = <<~CSV
      date,workout_type,exercise_name,muscle_group,set_number,rep_number,reps,weight,weight_unit,band,distance_meters,time_seconds,pace_per_km,workout_notes,set_notes
      2024-01-25,strength,Bench Press,chest,1,1,10,60,kg,,,,,,
      2024-01-25,strength,Bench Press,chest,2,1,8,65,kg,,,,,,
      2024-01-25,strength,Bench Press,chest,3,1,6,70,kg,,,,,,
    CSV

    build_parser(csv).parse
    workout =
      users(:john)
        .workouts
        .where(workout_import: workout_imports(:pending_import))
        .first
    assert_equal 3, workout.workout_sets.count
  end

  test "skips existing workouts" do
    csv = <<~CSV
      date,workout_type,exercise_name,muscle_group,set_number,rep_number,reps,weight,weight_unit,band,distance_meters,time_seconds,pace_per_km,workout_notes,set_notes
      #{Date.yesterday.iso8601},strength,Bench Press,chest,1,1,10,60,kg,,,,,,
    CSV

    result = build_parser(csv).parse
    assert_equal 1, result[:skipped]
    assert_equal 0, result[:imported]
  end

  private

  def strength_csv
    <<~CSV
      date,workout_type,exercise_name,muscle_group,set_number,rep_number,reps,weight,weight_unit,band,distance_meters,time_seconds,pace_per_km,workout_notes,set_notes
      2024-01-20,strength,Bench Press,chest,1,1,10,60,kg,,,,,,
      2024-01-20,strength,Bench Press,chest,1,2,8,65,kg,,,,,,
      2024-01-20,strength,Squat,legs,1,1,5,100,kg,,,,,,
    CSV
  end

  def run_csv
    <<~CSV
      date,workout_type,exercise_name,muscle_group,set_number,rep_number,reps,weight,weight_unit,band,distance_meters,time_seconds,pace_per_km,workout_notes,set_notes
      2024-01-21,run,,,,,,,,,5000,1800,6:00,Morning run,
    CSV
  end

  def find_workout_by_date(date_str)
    users(:john)
      .workouts
      .where(workout_import: workout_imports(:pending_import))
      .find { |w| w.started_at.to_date == Date.parse(date_str) }
  end

  def build_parser(csv_content)
    WorkoutImports::Parsers::WorkoutBroParser.new(
      csv_content: csv_content,
      user: users(:john),
      workout_import: workout_imports(:pending_import),
      exercise_matcher: WorkoutImports::ExerciseMatcher.new(user: users(:john))
    )
  end
end
