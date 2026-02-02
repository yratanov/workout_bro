describe WorkoutImports::Parsers::WorkoutBroParser do
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
    context "with strength workout data" do
      let(:csv_content) { <<~CSV }
          date,workout_type,exercise_name,muscle_group,set_number,rep_number,reps,weight,weight_unit,band,distance_meters,time_seconds,pace_per_km,workout_notes,set_notes
          2024-01-20,strength,Bench Press,chest,1,1,10,60,kg,,,,,,
          2024-01-20,strength,Bench Press,chest,1,2,8,65,kg,,,,,,
          2024-01-20,strength,Squat,legs,1,1,5,100,kg,,,,,,
        CSV

      it "imports strength workouts" do
        result = build_parser(csv_content).parse

        expect(result[:imported]).to eq(1)
      end

      it "creates workout sets for each exercise" do
        build_parser(csv_content).parse

        workout =
          user
            .workouts
            .where(workout_import: workout_import)
            .find { |w| w.started_at.to_date == Date.parse("2024-01-20") }

        expect(workout.workout_sets.count).to eq(2)
      end

      it "creates workout reps with correct data" do
        build_parser(csv_content).parse

        workout =
          user
            .workouts
            .where(workout_import: workout_import)
            .find { |w| w.started_at.to_date == Date.parse("2024-01-20") }

        bench_set =
          workout
            .workout_sets
            .joins(:exercise)
            .where(exercises: { name: "Bench Press" })
            .first

        expect(bench_set.workout_reps.count).to eq(2)
        expect(bench_set.workout_reps.map(&:weight)).to contain_exactly(
          60.0,
          65.0
        )
      end
    end

    context "with run workout data" do
      let(:csv_content) { <<~CSV }
          date,workout_type,exercise_name,muscle_group,set_number,rep_number,reps,weight,weight_unit,band,distance_meters,time_seconds,pace_per_km,workout_notes,set_notes
          2024-01-21,run,,,,,,,,,5000,1800,6:00,Morning run,
        CSV

      it "imports run workouts" do
        result = build_parser(csv_content).parse

        expect(result[:imported]).to eq(1)
      end

      it "creates run workout with correct data" do
        build_parser(csv_content).parse

        workout =
          user
            .workouts
            .where(workout_import: workout_import)
            .find { |w| w.started_at.to_date == Date.parse("2024-01-21") }

        expect(workout.run?).to be true
        expect(workout.distance).to eq(5000)
        expect(workout.time_in_seconds).to eq(1800)
        expect(workout.notes).to eq("Morning run")
      end
    end

    context "with mixed workout types" do
      let(:csv_content) { <<~CSV }
          date,workout_type,exercise_name,muscle_group,set_number,rep_number,reps,weight,weight_unit,band,distance_meters,time_seconds,pace_per_km,workout_notes,set_notes
          2024-01-22,strength,Bench Press,chest,1,1,10,60,kg,,,,,,
          2024-01-22,run,,,,,,,,,5000,1800,6:00,,
        CSV

      it "imports both strength and run workouts" do
        result = build_parser(csv_content).parse

        expect(result[:imported]).to eq(2)
      end
    end

    context "with band exercises" do
      let(:csv_content) { <<~CSV }
          date,workout_type,exercise_name,muscle_group,set_number,rep_number,reps,weight,weight_unit,band,distance_meters,time_seconds,pace_per_km,workout_notes,set_notes
          2024-01-23,strength,Banded Squat,legs,1,1,15,,kg,medium,,,,Felt good,
        CSV

      it "imports band information" do
        build_parser(csv_content).parse

        workout = user.workouts.where(workout_import: workout_import).first
        workout_rep = workout.workout_sets.first.workout_reps.first

        expect(workout_rep.band).to eq("medium")
      end
    end

    context "with workout and set notes" do
      let(:csv_content) { <<~CSV }
          date,workout_type,exercise_name,muscle_group,set_number,rep_number,reps,weight,weight_unit,band,distance_meters,time_seconds,pace_per_km,workout_notes,set_notes
          2024-01-24,strength,Bench Press,chest,1,1,10,60,kg,,,,,Great workout,Felt strong
        CSV

      it "imports notes" do
        build_parser(csv_content).parse

        workout = user.workouts.where(workout_import: workout_import).first

        expect(workout.notes).to eq("Great workout")
        expect(workout.workout_sets.first.notes).to eq("Felt strong")
      end
    end

    context "with multiple sets per exercise" do
      let(:csv_content) { <<~CSV }
          date,workout_type,exercise_name,muscle_group,set_number,rep_number,reps,weight,weight_unit,band,distance_meters,time_seconds,pace_per_km,workout_notes,set_notes
          2024-01-25,strength,Bench Press,chest,1,1,10,60,kg,,,,,,
          2024-01-25,strength,Bench Press,chest,2,1,8,65,kg,,,,,,
          2024-01-25,strength,Bench Press,chest,3,1,6,70,kg,,,,,,
        CSV

      it "creates separate sets" do
        build_parser(csv_content).parse

        workout = user.workouts.where(workout_import: workout_import).first

        expect(workout.workout_sets.count).to eq(3)
      end
    end

    context "when workout already exists for date" do
      let(:csv_content) { <<~CSV }
          date,workout_type,exercise_name,muscle_group,set_number,rep_number,reps,weight,weight_unit,band,distance_meters,time_seconds,pace_per_km,workout_notes,set_notes
          #{Date.yesterday.iso8601},strength,Bench Press,chest,1,1,10,60,kg,,,,,,
        CSV

      it "skips existing workouts" do
        result = build_parser(csv_content).parse

        expect(result[:skipped]).to eq(1)
        expect(result[:imported]).to eq(0)
      end
    end
  end
end
