class WorkoutImportJob < ApplicationJob
  queue_as :default

  def perform(workout_import:)
    WorkoutImports::CsvImporter.new(workout_import).call
  end
end
