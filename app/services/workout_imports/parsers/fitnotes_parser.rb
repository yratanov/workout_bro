require "csv"

module WorkoutImports
  module Parsers
    class FitnotesParser < BaseParser
      def parse
        imported = 0
        skipped = 0
        workouts_by_date = {}

        CSV.parse(csv_content, headers: true) do |row|
          date = parse_date(row["Date"])
          next unless date

          exercise_name = row["Exercise"]
          weight = find_weight(row)
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

        workouts_by_date.each do |date, exercises|
          exercises_data = exercises.map do |name, reps_data|
            { name: name, reps: reps_data }
          end

          if create_workout(date: date, exercises_data: exercises_data)
            imported += 1
          else
            skipped += 1
          end
        end

        { imported: imported, skipped: skipped }
      end

      private

      def find_weight(row)
        weight_kg = row["Weight (kg)"]
        return parse_weight(weight_kg) if weight_kg.present?

        weight_lbs = row["Weight (lbs)"]
        return parse_weight(weight_lbs) * 0.453592 if weight_lbs.present?

        weight_generic = row["Weight"]
        parse_weight(weight_generic)
      end
    end
  end
end
