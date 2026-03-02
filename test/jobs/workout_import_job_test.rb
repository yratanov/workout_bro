require "test_helper"

class WorkoutImportJobTest < ActiveJob::TestCase
  test "calls WorkoutImports::CsvImporter with the correct workout_import" do
    workout_import = workout_imports(:pending_import)
    mock_importer = mock("importer")
    mock_importer.expects(:call).once

    WorkoutImports::CsvImporter
      .expects(:new)
      .with(workout_import)
      .returns(mock_importer)

    WorkoutImportJob.new.perform(workout_import: workout_import)
  end
end
