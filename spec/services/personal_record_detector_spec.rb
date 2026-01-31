describe PersonalRecordDetector do
  fixtures :users, :exercises, :workouts, :workout_sets, :workout_reps, :muscles

  let(:user) { users(:john) }
  let(:bench_press) { exercises(:bench_press) }
  let(:pull_up) { exercises(:pull_up) }
  let(:banded_squat) { exercises(:banded_squat) }

  describe "#call" do
    context "with a completed strength workout" do
      let(:workout) do
        user.workouts.create!(
          workout_type: :strength,
          started_at: 1.hour.ago,
          ended_at: Time.current
        )
      end

      context "with weighted exercises" do
        let!(:workout_set) do
          workout.workout_sets.create!(
            exercise: bench_press,
            started_at: 1.hour.ago
          )
        end

        it "creates max_weight PR for first lift" do
          workout_set.workout_reps.create!(weight: 100, reps: 10)

          prs = described_class.new(workout: workout).call

          expect(prs.count).to eq(2)
          expect(prs.map(&:pr_type)).to contain_exactly(
            "max_weight",
            "max_volume"
          )
        end

        it "creates max_volume PR for high volume sets" do
          workout_set.workout_reps.create!(weight: 50, reps: 20)

          prs = described_class.new(workout: workout).call

          volume_pr = prs.find(&:max_volume?)
          expect(volume_pr.volume).to eq(1000)
        end

        it "does not create PR if weight is below existing PR" do
          user.personal_records.create!(
            exercise: bench_press,
            workout: workout,
            workout_rep:
              workout_set.workout_reps.create!(weight: 100, reps: 10),
            pr_type: :max_weight,
            weight: 150,
            reps: 5,
            achieved_on: 1.week.ago
          )

          new_workout =
            user.workouts.create!(
              workout_type: :strength,
              started_at: 30.minutes.ago,
              ended_at: Time.current
            )
          new_set =
            new_workout.workout_sets.create!(
              exercise: bench_press,
              started_at: 30.minutes.ago
            )
          new_set.workout_reps.create!(weight: 100, reps: 10)

          prs = described_class.new(workout: new_workout).call

          expect(prs.none?(&:max_weight?)).to be true
        end

        it "creates PR if weight beats existing PR" do
          existing_rep = workout_set.workout_reps.create!(weight: 100, reps: 10)
          user.personal_records.create!(
            exercise: bench_press,
            workout: workout,
            workout_rep: existing_rep,
            pr_type: :max_weight,
            weight: 100,
            reps: 10,
            achieved_on: 1.week.ago
          )

          new_workout =
            user.workouts.create!(
              workout_type: :strength,
              started_at: 30.minutes.ago,
              ended_at: Time.current
            )
          new_set =
            new_workout.workout_sets.create!(
              exercise: bench_press,
              started_at: 30.minutes.ago
            )
          new_set.workout_reps.create!(weight: 110, reps: 8)

          prs = described_class.new(workout: new_workout).call

          weight_pr = prs.find(&:max_weight?)
          expect(weight_pr).to be_present
          expect(weight_pr.weight).to eq(110)
        end
      end

      context "with bodyweight exercises" do
        let!(:workout_set) do
          workout.workout_sets.create!(
            exercise: pull_up,
            started_at: 1.hour.ago
          )
        end

        it "creates max_reps PR" do
          workout_set.workout_reps.create!(reps: 15)

          prs = described_class.new(workout: workout).call

          expect(prs.count).to eq(1)
          expect(prs.first).to be_max_reps
          expect(prs.first.reps).to eq(15)
        end

        it "does not create PR if reps are below existing PR" do
          existing_rep = workout_set.workout_reps.create!(reps: 20)
          user.personal_records.create!(
            exercise: pull_up,
            workout: workout,
            workout_rep: existing_rep,
            pr_type: :max_reps,
            reps: 20,
            achieved_on: 1.week.ago
          )

          new_workout =
            user.workouts.create!(
              workout_type: :strength,
              started_at: 30.minutes.ago,
              ended_at: Time.current
            )
          new_set =
            new_workout.workout_sets.create!(
              exercise: pull_up,
              started_at: 30.minutes.ago
            )
          new_set.workout_reps.create!(reps: 15)

          prs = described_class.new(workout: new_workout).call

          expect(prs).to be_empty
        end
      end

      context "with banded exercises" do
        let!(:workout_set) do
          workout.workout_sets.create!(
            exercise: banded_squat,
            started_at: 1.hour.ago
          )
        end

        it "tracks PRs separately per band type" do
          workout_set.workout_reps.create!(reps: 15, band: "light")
          workout_set.workout_reps.create!(reps: 12, band: "heavy")

          prs = described_class.new(workout: workout).call

          expect(prs.count).to eq(2)
          expect(prs.map(&:band)).to contain_exactly("light", "heavy")
        end

        it "does not beat PR with different band" do
          existing_rep =
            workout_set.workout_reps.create!(reps: 20, band: "light")
          user.personal_records.create!(
            exercise: banded_squat,
            workout: workout,
            workout_rep: existing_rep,
            pr_type: :max_reps,
            reps: 20,
            band: "light",
            achieved_on: 1.week.ago
          )

          new_workout =
            user.workouts.create!(
              workout_type: :strength,
              started_at: 30.minutes.ago,
              ended_at: Time.current
            )
          new_set =
            new_workout.workout_sets.create!(
              exercise: banded_squat,
              started_at: 30.minutes.ago
            )
          new_set.workout_reps.create!(reps: 25, band: "heavy")

          prs = described_class.new(workout: new_workout).call

          expect(prs.count).to eq(1)
          expect(prs.first.band).to eq("heavy")
        end
      end

      context "with multiple sets and reps" do
        it "detects PRs across all reps in workout" do
          set1 =
            workout.workout_sets.create!(
              exercise: bench_press,
              started_at: 1.hour.ago
            )
          set1.workout_reps.create!(weight: 80, reps: 10)

          set2 =
            workout.workout_sets.create!(
              exercise: bench_press,
              started_at: 50.minutes.ago
            )
          set2.workout_reps.create!(weight: 100, reps: 5)

          prs = described_class.new(workout: workout).call

          weight_pr = prs.find(&:max_weight?)
          expect(weight_pr.weight).to eq(100)

          volume_pr = prs.find(&:max_volume?)
          expect(volume_pr.volume).to eq(800) # 80 * 10
        end
      end
    end

    context "with a run workout" do
      let(:workout) do
        user.workouts.create!(
          workout_type: :run,
          started_at: 1.hour.ago,
          ended_at: Time.current,
          distance: 5000,
          time_in_seconds: 1800
        )
      end

      it "does not create any PRs" do
        prs = described_class.new(workout: workout).call
        expect(prs).to be_empty
      end
    end

    context "with an incomplete workout" do
      let(:workout) do
        user.workouts.create!(workout_type: :strength, started_at: 1.hour.ago)
      end

      it "does not create any PRs" do
        set =
          workout.workout_sets.create!(
            exercise: bench_press,
            started_at: 1.hour.ago
          )
        set.workout_reps.create!(weight: 100, reps: 10)

        prs = described_class.new(workout: workout).call
        expect(prs).to be_empty
      end
    end

    context "with zero weight" do
      let(:workout) do
        user.workouts.create!(
          workout_type: :strength,
          started_at: 1.hour.ago,
          ended_at: Time.current
        )
      end

      it "does not create max_weight PR" do
        set =
          workout.workout_sets.create!(
            exercise: bench_press,
            started_at: 1.hour.ago
          )
        set.workout_reps.create!(weight: 0, reps: 10)

        prs = described_class.new(workout: workout).call

        expect(prs.none?(&:max_weight?)).to be true
        expect(prs.none?(&:max_volume?)).to be true
      end
    end
  end
end
