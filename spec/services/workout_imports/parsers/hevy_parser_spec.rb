describe WorkoutImports::Parsers::HevyParser do
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
    context "with valid Hevy format" do
      let(:csv_content) { <<~CSV }
          title,start_time,end_time,exercise_title,weight_kg,reps,set_order
          Leg Day,2024-01-15T08:00:00Z,2024-01-15T09:00:00Z,Squat,100,10,1
          Leg Day,2024-01-15T08:00:00Z,2024-01-15T09:00:00Z,Squat,110,8,2
          Leg Day,2024-01-15T08:00:00Z,2024-01-15T09:00:00Z,Leg Press,200,12,1
          Push Day,2024-01-17T10:00:00Z,2024-01-17T11:00:00Z,Bench Press,60,10,1
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

      it "creates workout reps with correct weight from weight_kg" do
        build_parser(csv_content).parse

        jan15_workout =
          user
            .workouts
            .where(workout_import: workout_import)
            .find { |w| w.started_at.to_date == Date.parse("2024-01-15") }

        squat_set =
          jan15_workout
            .workout_sets
            .joins(:exercise)
            .where(exercises: { name: "Squat" })
            .first

        expect(squat_set.workout_reps.count).to eq(2)
        expect(squat_set.workout_reps.map(&:weight)).to contain_exactly(
          100.0,
          110.0
        )
      end
    end

    context "with ISO 8601 datetime format" do
      let(:csv_content) { <<~CSV }
          title,start_time,end_time,exercise_title,weight_kg,reps
          Morning,2024-01-15T08:30:00+02:00,2024-01-15T09:30:00+02:00,Deadlift,140,5
        CSV

      it "parses ISO 8601 datetime correctly" do
        result = build_parser(csv_content).parse

        expect(result[:imported]).to eq(1)
      end
    end

    context "with missing weight" do
      let(:csv_content) { <<~CSV }
          title,start_time,end_time,exercise_title,weight_kg,reps
          Morning,2024-01-15T08:00:00Z,2024-01-15T09:00:00Z,Pull-Up,,15
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

    context "with invalid datetime" do
      let(:csv_content) { <<~CSV }
          title,start_time,end_time,exercise_title,weight_kg,reps
          Morning,not-a-date,not-a-date,Squat,100,10
        CSV

      it "skips rows with invalid datetime" do
        result = build_parser(csv_content).parse

        expect(result[:imported]).to eq(0)
      end
    end
  end
end
