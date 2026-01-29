describe "Stats" do
  fixtures :users, :workouts

  let(:user) { users(:john) }

  before { sign_in(user) }

  describe "GET /stats" do
    it "returns success" do
      get stats_path
      expect(response).to have_http_status(:success)
    end

    context "with workouts that have time_in_seconds" do
      before do
        user.workouts.create!(
          workout_type: :strength,
          date: Date.today,
          started_at: 1.hour.ago,
          ended_at: Time.current,
          time_in_seconds: 3600
        )
      end

      it "displays hours per week data" do
        get stats_path
        expect(response).to have_http_status(:success)
      end
    end

    context "with run workouts that have distance" do
      before do
        user.workouts.create!(
          workout_type: :run,
          date: Date.today,
          started_at: 1.hour.ago,
          ended_at: Time.current,
          distance: 5000,
          time_in_seconds: 1800
        )
      end

      it "displays distance per week data" do
        get stats_path
        expect(response).to have_http_status(:success)
      end
    end

    context "with completed workouts" do
      before do
        user.workouts.create!(
          workout_type: :strength,
          date: Date.today,
          started_at: 1.hour.ago,
          ended_at: Time.current,
          time_in_seconds: 3600
        )
        user.workouts.create!(
          workout_type: :run,
          date: Date.today,
          started_at: 2.hours.ago,
          ended_at: 1.hour.ago,
          distance: 3000,
          time_in_seconds: 1800
        )
      end

      it "displays workouts per week data" do
        get stats_path
        expect(response).to have_http_status(:success)
      end
    end

    context "without any workouts" do
      before { user.workouts.destroy_all }

      it "returns success with empty data" do
        get stats_path
        expect(response).to have_http_status(:success)
      end
    end
  end
end
