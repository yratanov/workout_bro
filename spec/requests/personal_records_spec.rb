describe "PersonalRecords" do
  fixtures :users,
           :exercises,
           :workouts,
           :workout_sets,
           :workout_reps,
           :personal_records

  let(:user) { users(:john) }

  before { sign_in(user) }

  describe "GET /personal_records" do
    it "returns success" do
      get personal_records_path
      expect(response).to have_http_status(:success)
    end

    it "displays personal records" do
      get personal_records_path
      expect(response.body).to include("Personal Records")
    end

    context "with no personal records" do
      before { user.personal_records.destroy_all }

      it "shows empty state message" do
        get personal_records_path
        expect(response.body).to include("No personal records yet")
      end
    end

    context "with personal records" do
      it "displays PR exercise name" do
        get personal_records_path
        expect(response.body).to include("Bench Press")
      end

      it "displays PR type badge" do
        get personal_records_path
        expect(response.body).to include("Max Weight")
      end

      it "groups PRs by date" do
        get personal_records_path
        pr = personal_records(:bench_press_max_weight)
        expect(response.body).to include(I18n.l(pr.achieved_on, format: :long))
      end
    end

    context "with banded PRs" do
      before do
        banded_squat = exercises(:banded_squat)
        workout = workouts(:completed_workout)
        rep =
          workout
            .workout_sets
            .create!(exercise: banded_squat, started_at: 1.hour.ago)
            .workout_reps
            .create!(reps: 15, band: "heavy")

        user.personal_records.create!(
          exercise: banded_squat,
          workout: workout,
          workout_rep: rep,
          pr_type: :max_reps,
          reps: 15,
          band: "heavy",
          achieved_on: Date.today
        )
      end

      it "displays band badge" do
        get personal_records_path
        expect(response.body).to include("Heavy Band")
      end
    end
  end
end
