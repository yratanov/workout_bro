module WorkoutImports
  module Parsers
    class CustomFormatParser < BaseParser
      def parse
        imported = 0
        skipped = 0
        current_date = nil
        current_exercises = []

        csv_content.each_line do |line|
          line = line.strip
          next if line.blank?

          if date_line?(line)
            if current_date && current_exercises.any?
              if create_workout(date: current_date, exercises_data: current_exercises)
                imported += 1
              else
                skipped += 1
              end
            end

            current_date = parse_date_line(line)
            current_exercises = []
          elsif current_date
            exercise_data = parse_exercise_line(line)
            if exercise_data
              current_exercises << exercise_data
            else
              skipped += 1
            end
          end
        end

        if current_date && current_exercises.any?
          if create_workout(date: current_date, exercises_data: current_exercises)
            imported += 1
          else
            skipped += 1
          end
        end

        { imported: imported, skipped: skipped }
      end

      private

      def date_line?(line)
        parts = line.split(",").map(&:strip)
        return false if parts.empty?

        first_part = parts.first
        return false if first_part.blank?

        date = parse_date(first_part)
        date.present? && parts[1..].all? { |p| p.blank? || p.empty? }
      end

      def parse_date_line(line)
        parts = line.split(",")
        parse_date(parts.first)
      end

      def parse_exercise_line(line)
        parts = line.split(",").map(&:strip)
        return nil if parts.empty?

        exercise_name = parts.first
        return nil if exercise_name.blank?

        reps_data = parts[1..].map { |part| parse_rep_notation(part) }.compact

        return nil if reps_data.empty?

        { name: exercise_name, reps: reps_data }
      end

      def parse_rep_notation(notation)
        return nil if notation.blank?

        notation = notation.to_s.strip
        return nil if notation.empty?

        notation = notation.tr("х", "x")

        if notation.include?("x")
          weight_str, reps_str = notation.split("x", 2)
          weight = parse_weight(weight_str)
          reps = parse_reps(reps_str)

          return nil if weight.nil? || reps.nil? || reps.zero?

          { weight: weight, reps: reps, band: nil }
        else
          reps = parse_reps(notation)
          return nil if reps.nil? || reps.zero?

          { weight: nil, reps: reps, band: nil }
        end
      end
    end
  end
end
