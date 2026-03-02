require "test_helper"

class WorkoutImports::CsvImporterTest < ActiveSupport::TestCase
  test "imports workouts from custom format CSV" do
    workout_import = workout_imports(:pending_import)
    attach_csv(workout_import, custom_format_csv)

    result = WorkoutImports::CsvImporter.new(workout_import).call

    assert_equal 2, result[:imported]
    assert workout_import.reload.completed?
  end

  test "creates workout records with correct associations" do
    user = users(:john)
    workout_import = workout_imports(:pending_import)
    attach_csv(workout_import, custom_format_csv)

    WorkoutImports::CsvImporter.new(workout_import).call

    assert_equal 2, user.workouts.where(workout_import: workout_import).count
  end

  test "updates workout_import counters" do
    workout_import = workout_imports(:pending_import)
    attach_csv(workout_import, custom_format_csv)

    WorkoutImports::CsvImporter.new(workout_import).call

    workout_import.reload
    assert_equal 2, workout_import.imported_count
    assert_equal 0, workout_import.skipped_count
  end

  test "sets status to failed when import fails" do
    workout_import = workout_imports(:pending_import)
    workout_import.file.attach(
      io: StringIO.new("invalid"),
      filename: "bad.csv",
      content_type: "text/csv"
    )
    WorkoutImports::FormatDetector
      .any_instance
      .stubs(:parser_class)
      .raises(StandardError, "Test error")

    WorkoutImports::CsvImporter.new(workout_import).call

    assert workout_import.reload.failed?
  end

  test "records error details when import fails" do
    workout_import = workout_imports(:pending_import)
    workout_import.file.attach(
      io: StringIO.new("invalid"),
      filename: "bad.csv",
      content_type: "text/csv"
    )
    WorkoutImports::FormatDetector
      .any_instance
      .stubs(:parser_class)
      .raises(StandardError, "Test error")

    WorkoutImports::CsvImporter.new(workout_import).call

    assert_equal "Test error", workout_import.reload.error_details["message"]
  end

  private

  def custom_format_csv
    <<~CSV
      2024-01-15,,,,
      Bench Press,60x10,70x8,,

      2024-01-17,,,,
      Squat,100x5,110x5,,
    CSV
  end

  def attach_csv(workout_import, content)
    workout_import.file.attach(
      io: StringIO.new(content),
      filename: "workouts.csv",
      content_type: "text/csv"
    )
  end
end
