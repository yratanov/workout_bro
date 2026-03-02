require "csv"

module WorkoutImports
  module Parsers
    class HevyParser < BaseParser
      def parse
        workouts_by_date = {}

        CSV.parse(csv_content, headers: true) do |row|
          start_time = row["start_time"]
          date = parse_datetime_to_date(start_time)
          next unless date

          exercise_name = row["exercise_title"]
          weight = parse_weight(row["weight_kg"])
          reps = parse_reps(row["reps"])

          next if exercise_name.blank? || reps.nil? || reps.zero?

          workouts_by_date[date] ||= {}
          workouts_by_date[date][exercise_name] ||= []
          workouts_by_date[date][exercise_name] << {
            weight: weight,
            reps: reps,
            band: nil
          }
        end

        import_workouts(workouts_by_date)
      end

      private

      def parse_datetime_to_date(value)
        return nil if value.blank?

        DateTime.parse(value.to_s).to_date
      rescue ArgumentError
        nil
      end
    end
  end
end
