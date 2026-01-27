module WorkoutImports
  class FormatDetector
    FORMATS = {
      strong_app: {
        headers: %w[Date Workout\ Name Exercise\ Name Set\ Order Weight Reps],
        parser: "WorkoutImports::Parsers::StrongAppParser"
      },
      hevy: {
        headers: %w[title start_time end_time exercise_title weight_kg reps],
        parser: "WorkoutImports::Parsers::HevyParser"
      },
      fitnotes: {
        headers: %w[Date Exercise Category Weight],
        parser: "WorkoutImports::Parsers::FitnotesParser"
      }
    }.freeze

    def initialize(csv_content)
      @csv_content = csv_content
    end

    def detect
      first_line = @csv_content.lines.first&.strip
      return :custom_format if first_line.blank?

      FORMATS.each do |format_name, config|
        headers = config[:headers]
        if headers_match?(first_line, headers)
          return format_name
        end
      end

      :custom_format
    end

    def parser_class
      format = detect

      if format == :custom_format
        WorkoutImports::Parsers::CustomFormatParser
      else
        FORMATS[format][:parser].constantize
      end
    end

    private

    def headers_match?(first_line, expected_headers)
      line_headers = first_line.split(",").map(&:strip).map(&:downcase)
      expected_normalized = expected_headers.map(&:downcase)

      expected_normalized.all? { |h| line_headers.include?(h) }
    end
  end
end
