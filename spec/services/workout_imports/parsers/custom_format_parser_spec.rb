require "rails_helper"

RSpec.describe WorkoutImports::Parsers::CustomFormatParser do
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
    context "with standard format" do
      let(:csv_content) do
        <<~CSV
          2024-01-15,,,,
          Bench Press,60x10,70x8,,
          Squat,100x5,110x5,,

          2024-01-17,,,,
          Deadlift,120x3,130x3,,
        CSV
      end

      it "imports multiple workouts" do
        result = build_parser(csv_content).parse

        expect(result[:imported]).to eq(2)
      end

      it "creates workout records" do
        build_parser(csv_content).parse

        workouts = user.workouts.where(workout_import: workout_import)
        expect(workouts.count).to eq(2)
      end

      it "creates workout sets for each exercise" do
        build_parser(csv_content).parse

        workout = user.workouts.where(workout_import: workout_import).first
        expect(workout.workout_sets.count).to eq(2)
      end

      it "creates workout reps with correct weight and reps" do
        build_parser(csv_content).parse

        workout = user.workouts.where(workout_import: workout_import)
                      .order(:started_at).first
        bench_set = workout.workout_sets.joins(:exercise)
                          .where(exercises: { name: "Bench Press" }).first

        expect(bench_set.workout_reps.count).to eq(2)
        expect(bench_set.workout_reps.first.weight).to eq(60.0)
        expect(bench_set.workout_reps.first.reps).to eq(10)
      end
    end

    context "with Cyrillic x (х)" do
      let(:csv_content) do
        <<~CSV
          2024-01-15,,,,
          Deadlift,100х8,110х6,,
        CSV
      end

      it "parses Cyrillic x correctly" do
        result = build_parser(csv_content).parse

        expect(result[:imported]).to eq(1)

        workout = user.workouts.where(workout_import: workout_import).first
        workout_set = workout.workout_sets.first
        expect(workout_set.workout_reps.first.weight).to eq(100.0)
        expect(workout_set.workout_reps.first.reps).to eq(8)
      end
    end

    context "with bodyweight exercises (reps only)" do
      let(:csv_content) do
        <<~CSV
          2024-01-15,,,,
          Pull-Up,15,12,10,
        CSV
      end

      it "parses reps without weight" do
        result = build_parser(csv_content).parse

        expect(result[:imported]).to eq(1)

        workout = user.workouts.where(workout_import: workout_import).first
        workout_set = workout.workout_sets.first
        expect(workout_set.workout_reps.count).to eq(3)
        expect(workout_set.workout_reps.first.weight).to be_nil
        expect(workout_set.workout_reps.first.reps).to eq(15)
      end
    end

    context "with empty lines between workouts" do
      let(:csv_content) do
        <<~CSV
          2024-01-15,,,,
          Bench Press,60x10,,


          2024-01-16,,,,
          Squat,100x5,,
        CSV
      end

      it "handles empty lines correctly" do
        result = build_parser(csv_content).parse

        expect(result[:imported]).to eq(2)
      end
    end

    context "with new exercises" do
      let(:csv_content) do
        <<~CSV
          2024-01-15,,,,
          New Exercise,50x10,,
        CSV
      end

      it "creates new exercises for the user" do
        expect {
          build_parser(csv_content).parse
        }.to change { user.exercises.count }.by(1)

        expect(user.exercises.find_by(name: "New Exercise")).to be_present
      end
    end

    context "with existing exercises (case-insensitive)" do
      let(:csv_content) do
        <<~CSV
          2024-01-15,,,,
          bench press,60x10,,
        CSV
      end

      it "matches existing exercises case-insensitively" do
        expect {
          build_parser(csv_content).parse
        }.not_to change { user.exercises.count }
      end
    end

    context "with empty workout (date only)" do
      let(:csv_content) do
        <<~CSV
          2024-01-15,,,,
        CSV
      end

      it "does not create workout for empty date" do
        result = build_parser(csv_content).parse

        expect(result[:imported]).to eq(0)
      end
    end

    context "with duplicate dates (workout already exists)" do
      let(:csv_content) do
        <<~CSV
          2024-01-15,,,,
          Bench Press,60x10,70x8,,

          2024-01-17,,,,
          Squat,100x5,110x5,,
        CSV
      end

      before do
        user.workouts.create!(
          workout_type: :strength,
          started_at: Date.parse("2024-01-15").to_datetime.change(hour: 10),
          ended_at: Date.parse("2024-01-15").to_datetime.change(hour: 11)
        )
      end

      it "skips workouts for dates that already have a workout" do
        result = build_parser(csv_content).parse

        expect(result[:imported]).to eq(1)
        expect(result[:skipped]).to eq(1)
      end

      it "only creates workout for the new date" do
        build_parser(csv_content).parse

        imported_workouts = user.workouts.where(workout_import: workout_import)
        expect(imported_workouts.count).to eq(1)
        expect(imported_workouts.first.started_at.to_date).to eq(Date.parse("2024-01-17"))
      end

      it "does not create duplicate workouts on re-import" do
        build_parser(csv_content).parse

        second_import = create_workout_import(user: user)
        second_parser = described_class.new(
          csv_content: csv_content,
          user: user,
          workout_import: second_import,
          exercise_matcher: WorkoutImports::ExerciseMatcher.new(user: user)
        )

        result = second_parser.parse

        expect(result[:imported]).to eq(0)
        expect(result[:skipped]).to eq(2)
      end
    end
  end
end
