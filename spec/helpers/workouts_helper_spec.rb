describe WorkoutsHelper do
  fixtures :users, :workouts, :workout_routine_days

  describe "#modal_title" do
    context "for a run workout" do
      let(:workout) do
        Workout.new(workout_type: :run, created_at: Date.new(2024, 1, 15))
      end

      it "returns Run with date" do
        expect(helper.modal_title(workout)).to eq("Run · 15 Jan 2024")
      end
    end

    context "for a strength workout with routine day" do
      let(:workout) do
        Workout.new(
          workout_type: :strength,
          created_at: Date.new(2024, 1, 15),
          workout_routine_day: workout_routine_days(:push_day)
        )
      end

      it "returns routine day name with date" do
        expect(helper.modal_title(workout)).to eq("Push Day · 15 Jan 2024")
      end
    end

    context "for a strength workout without routine day" do
      let(:workout) do
        Workout.new(
          workout_type: :strength,
          created_at: Date.new(2024, 1, 15),
          workout_routine_day: nil
        )
      end

      it "returns Strength with date" do
        expect(helper.modal_title(workout)).to eq("Strength · 15 Jan 2024")
      end
    end
  end

  describe "#run_pace" do
    context "for a run workout" do
      let(:started_at) { Time.zone.parse("2024-01-15 08:00:00") }
      let(:ended_at) { Time.zone.parse("2024-01-15 08:30:00") }

      let(:workout) do
        Workout.new(
          workout_type: :run,
          started_at: started_at,
          ended_at: ended_at,
          distance: 5000
        )
      end

      it "calculates pace correctly" do
        expect(helper.run_pace(workout)).to eq("6:00 min/km")
      end
    end

    context "for a non-run workout" do
      let(:workout) { Workout.new(workout_type: :strength) }

      it "returns nil" do
        expect(helper.run_pace(workout)).to be_nil
      end
    end

    context "when started_at is missing" do
      let(:workout) do
        Workout.new(workout_type: :run, ended_at: Time.current, distance: 5000)
      end

      it "returns nil" do
        expect(helper.run_pace(workout)).to be_nil
      end
    end

    context "when ended_at is missing" do
      let(:workout) do
        Workout.new(
          workout_type: :run,
          started_at: Time.current,
          distance: 5000
        )
      end

      it "returns nil" do
        expect(helper.run_pace(workout)).to be_nil
      end
    end

    context "when distance is zero" do
      let(:workout) do
        Workout.new(
          workout_type: :run,
          started_at: 30.minutes.ago,
          ended_at: Time.current,
          distance: 0
        )
      end

      it "returns nil" do
        expect(helper.run_pace(workout)).to be_nil
      end
    end

    context "when distance is nil" do
      let(:workout) do
        Workout.new(
          workout_type: :run,
          started_at: 30.minutes.ago,
          ended_at: Time.current,
          distance: nil
        )
      end

      it "returns nil" do
        expect(helper.run_pace(workout)).to be_nil
      end
    end
  end
end
