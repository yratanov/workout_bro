class ExercisesImportJob < ApplicationJob
  queue_as :default

  def perform(user:)
    ExercisesImporter.new(user: user).call
  end
end
