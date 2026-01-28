describe WorkoutImports::Parsers::FitnotesParser do
  fixtures :all

  let(:user) { users(:john) }
  let(:workout_import) { workout_imports(:pending_import) }
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
    context "with valid FitNotes format (kg)" do
      let(:csv_content) { <<~CSV }
          Date,Exercise,Category,Weight (kg),Reps,Notes
          2024-01-15,Bench Press,Chest,60,10,
          2024-01-15,Bench Press,Chest,70,8,
          2024-01-15,Squat,Legs,100,5,
          2024-01-17,Deadlift,Back,120,3,
        CSV

      it "imports workouts grouped by date" do
        result = build_parser(csv_content).parse

        expect(result[:imported]).to eq(2)
      end

      it "creates workout sets for each exercise" do
        build_parser(csv_content).parse

        jan15_workout =
          user
            .workouts
            .where(workout_import: workout_import)
            .find { |w| w.started_at.to_date == Date.parse("2024-01-15") }

        expect(jan15_workout.workout_sets.count).to eq(2)
      end

      it "creates workout reps with correct weight" do
        build_parser(csv_content).parse

        jan15_workout =
          user
            .workouts
            .where(workout_import: workout_import)
            .find { |w| w.started_at.to_date == Date.parse("2024-01-15") }

        bench_set =
          jan15_workout
            .workout_sets
            .joins(:exercise)
            .where(exercises: { name: "Bench Press" })
            .first

        expect(bench_set.workout_reps.count).to eq(2)
        expect(bench_set.workout_reps.map(&:weight)).to contain_exactly(
          60.0,
          70.0
        )
      end
    end

    context "with pounds weight" do
      let(:csv_content) { <<~CSV }
          Date,Exercise,Category,Weight (lbs),Reps
          2024-01-15,Bench Press,Chest,132,10
        CSV

      it "converts pounds to kilograms" do
        build_parser(csv_content).parse

        workout = user.workouts.where(workout_import: workout_import).first
        workout_rep = workout.workout_sets.first.workout_reps.first

        expect(workout_rep.weight).to be_within(0.1).of(59.87)
      end
    end

    context "with generic Weight column" do
      let(:csv_content) { <<~CSV }
          Date,Exercise,Category,Weight,Reps
          2024-01-15,Bench Press,Chest,60,10
        CSV

      it "parses generic weight column" do
        result = build_parser(csv_content).parse

        expect(result[:imported]).to eq(1)

        workout = user.workouts.where(workout_import: workout_import).first
        workout_rep = workout.workout_sets.first.workout_reps.first
        expect(workout_rep.weight).to eq(60.0)
      end
    end

    context "with missing weight" do
      let(:csv_content) { <<~CSV }
          Date,Exercise,Category,Weight (kg),Reps
          2024-01-15,Pull-Up,Back,,15
        CSV

      it "imports with nil weight" do
        result = build_parser(csv_content).parse

        expect(result[:imported]).to eq(1)

        workout = user.workouts.where(workout_import: workout_import).first
        workout_rep = workout.workout_sets.first.workout_reps.first
        expect(workout_rep.weight).to be_nil
        expect(workout_rep.reps).to eq(15)
      end
    end

    context "with invalid date" do
      let(:csv_content) { <<~CSV }
          Date,Exercise,Category,Weight (kg),Reps
          invalid,Bench Press,Chest,60,10
        CSV

      it "skips rows with invalid dates" do
        result = build_parser(csv_content).parse

        expect(result[:imported]).to eq(0)
      end
    end

    context "with zero reps" do
      let(:csv_content) { <<~CSV }
          Date,Exercise,Category,Weight (kg),Reps
          2024-01-15,Bench Press,Chest,60,0
        CSV

      it "skips rows with zero reps" do
        result = build_parser(csv_content).parse

        expect(result[:imported]).to eq(0)
      end
    end

    context "with missing exercise name" do
      let(:csv_content) { <<~CSV }
          Date,Exercise,Category,Weight (kg),Reps
          2024-01-15,,Chest,60,10
        CSV

      it "skips rows with missing exercise" do
        result = build_parser(csv_content).parse

        expect(result[:imported]).to eq(0)
      end
    end
  end
end
