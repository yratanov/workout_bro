module WorkoutImports
  module Parsers
    class BaseParser
      attr_reader :csv_content, :user, :workout_import, :exercise_matcher

      def initialize(csv_content:, user:, workout_import:, exercise_matcher:)
        @csv_content = csv_content
        @user = user
        @workout_import = workout_import
        @exercise_matcher = exercise_matcher
      end

      def parse
        raise NotImplementedError, "Subclasses must implement #parse"
      end

      protected

      def parse_weight(value)
        return nil if value.blank?

        cleaned = value.to_s.gsub(/[^\d.,]/, "").tr(",", ".")
        cleaned.to_f
      end

      def parse_reps(value)
        return nil if value.blank?

        value.to_s.gsub(/\D/, "").to_i
      end

      def parse_date(value)
        return nil if value.blank?

        Date.parse(value.to_s)
      rescue ArgumentError
        nil
      end

      def create_workout(date:, exercises_data:)
        return nil if workout_exists_for_date?(date)

        started_at = date.to_datetime.change(hour: 9)
        ended_at = started_at + 1.hour

        workout =
          user.workouts.create!(
            workout_type: :strength,
            started_at: started_at,
            ended_at: ended_at,
            workout_import: workout_import
          )

        exercises_data.each do |exercise_data|
          create_workout_set(workout, exercise_data)
        end

        workout
      end

      def workout_exists_for_date?(date)
        user
          .workouts
          .where(started_at: date.beginning_of_day..date.end_of_day)
          .exists?
      end

      def create_workout_set(workout, exercise_data)
        exercise = exercise_matcher.match(exercise_data[:name])
        return unless exercise

        workout_set =
          workout.workout_sets.create!(
            exercise: exercise,
            started_at: workout.started_at,
            ended_at: workout.ended_at
          )

        exercise_data[:reps].each do |rep_data|
          workout_set.workout_reps.create!(
            weight: rep_data[:weight],
            reps: rep_data[:reps],
            band: rep_data[:band]
          )
        end
      end
    end
  end
end
