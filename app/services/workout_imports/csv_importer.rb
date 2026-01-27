module WorkoutImports
  class CsvImporter
    attr_reader :workout_import

    def initialize(workout_import)
      @workout_import = workout_import
    end

    def call
      workout_import.in_progress!

      csv_content = read_file_content
      parser = build_parser(csv_content)

      result = parser.parse

      workout_import.update!(
        status: :completed,
        imported_count: result[:imported],
        skipped_count: result[:skipped]
      )

      result
    rescue StandardError => e
      workout_import.update!(
        status: :failed,
        error_details: { message: e.message, backtrace: e.backtrace&.first(5) }
      )

      { imported: 0, skipped: 0, error: e.message }
    end

    private

    def read_file_content
      if workout_import.file.attached?
        workout_import.file.download
      else
        raise "No file attached to import"
      end
    end

    def build_parser(csv_content)
      detector = FormatDetector.new(csv_content)
      parser_class = detector.parser_class

      parser_class.new(
        csv_content: csv_content,
        user: workout_import.user,
        workout_import: workout_import,
        exercise_matcher: ExerciseMatcher.new(user: workout_import.user)
      )
    end
  end
end
