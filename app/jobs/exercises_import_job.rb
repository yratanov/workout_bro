class ExercisesImportJob < ApplicationJob
  queue_as :default

  def perform(locale: "en")
    ExercisesImporter.new(locale: locale).call
  end
end
