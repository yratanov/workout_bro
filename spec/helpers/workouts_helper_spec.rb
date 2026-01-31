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

  describe "#format_volume" do
    it "formats small volumes with unit" do
      expect(helper.format_volume(500, "kg")).to eq("500kg")
    end

    it "formats large volumes in tonnes" do
      expect(helper.format_volume(1500, "kg")).to eq("1.5t")
    end

    it "formats whole tonnes without decimal" do
      expect(helper.format_volume(2000, "kg")).to eq("2t")
    end

    it "handles zero volume" do
      expect(helper.format_volume(0, "kg")).to eq("0kg")
    end

    it "handles nil volume" do
      expect(helper.format_volume(nil, "kg")).to eq("0kg")
    end

    it "respects user's weight unit" do
      expect(helper.format_volume(500, "lbs")).to eq("500lbs")
    end

    it "uses kg as default unit" do
      expect(helper.format_volume(500)).to eq("500kg")
    end

    it "rounds decimal volumes" do
      expect(helper.format_volume(1234.567, "kg")).to eq("1.2t")
    end
  end

  describe "#comparison_class" do
    it "returns green class for positive diff" do
      expect(helper.comparison_class(10)).to eq("text-green-400")
    end

    it "returns red class for negative diff" do
      expect(helper.comparison_class(-10)).to eq("text-red-400")
    end

    it "returns slate class for zero diff" do
      expect(helper.comparison_class(0)).to eq("text-slate-400")
    end

    it "returns slate class for nil diff" do
      expect(helper.comparison_class(nil)).to eq("text-slate-400")
    end
  end

  describe "#comparison_arrow" do
    it "returns chevron_up for positive diff" do
      expect(helper.comparison_arrow(10)).to eq("chevron_up")
    end

    it "returns chevron_down for negative diff" do
      expect(helper.comparison_arrow(-10)).to eq("chevron_down")
    end

    it "returns minus for zero diff" do
      expect(helper.comparison_arrow(0)).to eq("minus")
    end

    it "returns minus for nil diff" do
      expect(helper.comparison_arrow(nil)).to eq("minus")
    end
  end

  describe "#format_pace" do
    it "formats pace in minutes and seconds" do
      expect(helper.format_pace(360)).to eq("6:00")
    end

    it "formats pace with single digit seconds" do
      expect(helper.format_pace(365)).to eq("6:05")
    end

    it "returns nil for nil pace" do
      expect(helper.format_pace(nil)).to be_nil
    end

    it "returns nil for zero pace" do
      expect(helper.format_pace(0)).to be_nil
    end

    it "returns nil for negative pace" do
      expect(helper.format_pace(-10)).to be_nil
    end
  end

  describe "#format_pace_diff" do
    it "formats small differences in seconds only" do
      expect(helper.format_pace_diff(15)).to eq("15s")
    end

    it "formats larger differences in minutes and seconds" do
      expect(helper.format_pace_diff(75)).to eq("1:15")
    end

    it "handles negative differences (absolute value)" do
      expect(helper.format_pace_diff(-15)).to eq("15s")
    end

    it "returns nil for nil input" do
      expect(helper.format_pace_diff(nil)).to be_nil
    end
  end

  describe "#pr_type_label" do
    it "returns translated label for max_weight" do
      expect(helper.pr_type_label(:max_weight)).to eq("Max Weight")
    end

    it "returns translated label for max_volume" do
      expect(helper.pr_type_label(:max_volume)).to eq("Max Volume")
    end

    it "returns translated label for max_reps" do
      expect(helper.pr_type_label(:max_reps)).to eq("Max Reps")
    end
  end
end
