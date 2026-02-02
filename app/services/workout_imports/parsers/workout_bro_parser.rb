# frozen_string_literal: true

require "csv"

module WorkoutImports
  module Parsers
    class WorkoutBroParser < BaseParser
      def parse
        imported = 0
        skipped = 0
        workouts_by_date = {}

        CSV.parse(csv_content, headers: true) do |row|
          date = parse_date(row["date"])
          next unless date

          workout_type = row["workout_type"]
          workouts_by_date[date] ||= { strength: {}, runs: [] }

          if workout_type == "run"
            parse_run_row(row, workouts_by_date[date])
          else
            parse_strength_row(row, workouts_by_date[date])
          end
        end

        workouts_by_date.each do |date, data|
          if data[:strength].any?
            if create_strength_workout(
                 date: date,
                 exercises: data[:strength],
                 notes: data[:workout_notes]
               )
              imported += 1
            else
              skipped += 1
            end
          end

          data[:runs].each do |run_data|
            if create_run_workout(date: date, run_data: run_data)
              imported += 1
            else
              skipped += 1
            end
          end
        end

        { imported: imported, skipped: skipped }
      end

      private

      def parse_strength_row(row, date_data)
        exercise_name = row["exercise_name"]
        return if exercise_name.blank?

        reps = parse_reps(row["reps"])
        return if reps.nil? || reps.zero?

        weight = parse_weight(row["weight"])
        band = row["band"].presence
        set_number = row["set_number"].to_i
        set_notes = row["set_notes"].presence

        date_data[:strength][exercise_name] ||= {}
        date_data[:strength][exercise_name][set_number] ||= {
          reps: [],
          notes: set_notes
        }
        date_data[:strength][exercise_name][set_number][:reps] << {
          weight: weight,
          reps: reps,
          band: band
        }

        date_data[:workout_notes] ||= row["workout_notes"].presence
      end

      def parse_run_row(row, date_data)
        distance = row["distance_meters"].to_i
        time = row["time_seconds"].to_i

        return if distance.zero? && time.zero?

        date_data[:runs] << {
          distance: distance,
          time: time,
          notes: row["workout_notes"].presence
        }
      end

      def create_strength_workout(date:, exercises:, notes:)
        return nil if strength_workout_exists_for_date?(date)

        started_at = date.to_datetime.change(hour: 9)
        ended_at = started_at + 1.hour

        workout =
          user.workouts.create!(
            workout_type: :strength,
            started_at: started_at,
            ended_at: ended_at,
            notes: notes,
            workout_import: workout_import
          )

        exercises.each do |exercise_name, sets_data|
          exercise = exercise_matcher.match(exercise_name)
          next unless exercise

          sets_data.keys.sort.each do |set_number|
            set_data = sets_data[set_number]
            workout_set =
              workout.workout_sets.create!(
                exercise: exercise,
                started_at: started_at,
                ended_at: ended_at,
                notes: set_data[:notes]
              )

            set_data[:reps].each do |rep_data|
              workout_set.workout_reps.create!(
                weight: rep_data[:weight],
                reps: rep_data[:reps],
                band: rep_data[:band]
              )
            end
          end
        end

        workout
      end

      def create_run_workout(date:, run_data:)
        return nil if run_workout_exists_for_date?(date, run_data)

        started_at = date.to_datetime.change(hour: 9)
        time_seconds = run_data[:time].positive? ? run_data[:time] : 1800
        ended_at = started_at + time_seconds.seconds

        user.workouts.create!(
          workout_type: :run,
          started_at: started_at,
          ended_at: ended_at,
          distance: run_data[:distance],
          time_in_seconds: run_data[:time],
          notes: run_data[:notes],
          workout_import: workout_import
        )
      end

      def strength_workout_exists_for_date?(date)
        user
          .workouts
          .where(workout_type: :strength)
          .where(started_at: date.beginning_of_day..date.end_of_day)
          .exists?
      end

      def run_workout_exists_for_date?(date, run_data)
        user
          .workouts
          .where(workout_type: :run)
          .where(started_at: date.beginning_of_day..date.end_of_day)
          .where(distance: run_data[:distance])
          .exists?
      end
    end
  end
end
