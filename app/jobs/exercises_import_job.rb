class ExercisesImportJob < ApplicationJob
  queue_as :default

  def perform
    ExercisesImporter.new.call
  end
end
