class ExercisesImporter
  DEFAULT_PATH = Rails.root.join("db/data/exercises.csv")

  def initialize(path = DEFAULT_PATH)
    @path = path
  end

  def call
    require "csv"

    imported = 0
    skipped = 0

    CSV.foreach(@path, headers: true) do |row|
      exercise = Exercise.find_or_initialize_by(name: row["name"])

      if exercise.new_record?
        muscle = Muscle.find_by(name: row["muscles"]&.downcase)
        exercise.assign_attributes(
          muscle: muscle,
          with_weights: row["with_weights"] == "true",
          with_band: row["with_band"] == "true"
        )
        exercise.save!
        imported += 1
      else
        skipped += 1
      end
    end

    { imported: imported, skipped: skipped }
  end
end
