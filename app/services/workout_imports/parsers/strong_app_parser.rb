require "csv"

module WorkoutImports
  module Parsers
    class StrongAppParser < BaseParser
      def parse
        workouts_by_date = {}

        CSV.parse(csv_content, headers: true) do |row|
          date = parse_date(row["Date"])
          next unless date

          exercise_name = row["Exercise Name"]
          weight = parse_weight(row["Weight"])
          reps = parse_reps(row["Reps"])

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
    end
  end
end
