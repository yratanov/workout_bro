require "rails_helper"

RSpec.describe WorkoutImports::Parsers::StrongAppParser do
  fixtures :users, :exercises

  let(:user) { users(:one) }
  let(:workout_import) { create_workout_import(user: user) }
  let(:exercise_matcher) { WorkoutImports::ExerciseMatcher.new(user: user) }

  def build_parser(csv_content)
    described_class.new(
      csv_content: csv_content,
      user: user,
      workout_import: workout_import,
      exercise_matcher: exercise_matcher
    )
  end

  describe "#parse" do
    context "with valid Strong App format" do
      let(:csv_content) do
        <<~CSV
          Date,Workout Name,Exercise Name,Set Order,Weight,Reps,RPE,Notes
          2024-01-15,Morning,Bench Press,1,60,10,,
          2024-01-15,Morning,Bench Press,2,70,8,,
          2024-01-15,Morning,Squat,1,100,5,,
          2024-01-17,Evening,Deadlift,1,120,3,,
        CSV
      end

      it "imports workouts grouped by date" do
        result = build_parser(csv_content).parse

        expect(result[:imported]).to eq(2)
      end

      it "creates workout sets for each exercise" do
        build_parser(csv_content).parse

        jan15_workout = user.workouts.where(workout_import: workout_import)
                            .find { |w| w.started_at.to_date == Date.parse("2024-01-15") }

        expect(jan15_workout.workout_sets.count).to eq(2)
      end

      it "creates workout reps with correct data" do
        build_parser(csv_content).parse

        jan15_workout = user.workouts.where(workout_import: workout_import)
                            .find { |w| w.started_at.to_date == Date.parse("2024-01-15") }

        bench_set = jan15_workout.workout_sets.joins(:exercise)
                                 .where(exercises: { name: "Bench Press" }).first

        expect(bench_set.workout_reps.count).to eq(2)
        expect(bench_set.workout_reps.map(&:weight)).to contain_exactly(60.0, 70.0)
      end
    end

    context "with missing weight" do
      let(:csv_content) do
        <<~CSV
          Date,Workout Name,Exercise Name,Set Order,Weight,Reps
          2024-01-15,Morning,Pull-Up,1,,10
        CSV
      end

      it "imports with nil weight" do
        result = build_parser(csv_content).parse

        expect(result[:imported]).to eq(1)

        workout = user.workouts.where(workout_import: workout_import).first
        workout_rep = workout.workout_sets.first.workout_reps.first
        expect(workout_rep.weight).to be_nil
        expect(workout_rep.reps).to eq(10)
      end
    end

    context "with invalid date" do
      let(:csv_content) do
        <<~CSV
          Date,Workout Name,Exercise Name,Set Order,Weight,Reps
          invalid-date,Morning,Bench Press,1,60,10
        CSV
      end

      it "skips rows with invalid dates" do
        result = build_parser(csv_content).parse

        expect(result[:imported]).to eq(0)
      end
    end

    context "with zero reps" do
      let(:csv_content) do
        <<~CSV
          Date,Workout Name,Exercise Name,Set Order,Weight,Reps
          2024-01-15,Morning,Bench Press,1,60,0
        CSV
      end

      it "skips rows with zero reps" do
        result = build_parser(csv_content).parse

        expect(result[:imported]).to eq(0)
      end
    end
  end
end
