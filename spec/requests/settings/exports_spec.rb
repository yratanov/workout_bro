describe "Settings::Exports" do
  fixtures :all

  let(:user) { users(:john) }

  before { sign_in(user) }

  describe "GET /settings/exports" do
    it "returns success" do
      get settings_exports_path
      expect(response).to have_http_status(:success)
    end

    it "displays the export page" do
      get settings_exports_path
      expect(response.body).to include("Export Workouts")
    end

    it "shows workout and exercise counts" do
      get settings_exports_path
      expect(response.body).to include("Completed Workouts")
      expect(response.body).to include("Exercises")
    end
  end

  describe "POST /settings/exports" do
    it "returns a CSV file" do
      post settings_exports_path

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("text/csv")
    end

    it "sets the correct filename" do
      post settings_exports_path

      expect(response.headers["Content-Disposition"]).to include(
        "workout_bro_export_"
      )
      expect(response.headers["Content-Disposition"]).to include(".csv")
    end

    it "includes CSV headers" do
      post settings_exports_path

      csv_lines = response.body.lines
      headers = csv_lines.first.strip.split(",")

      expect(headers).to include("date")
      expect(headers).to include("workout_type")
      expect(headers).to include("exercise_name")
      expect(headers).to include("weight")
      expect(headers).to include("reps")
    end

    it "includes strength workout data" do
      post settings_exports_path

      expect(response.body).to include("strength")
      expect(response.body).to include("Bench Press")
    end

    it "includes run workout data" do
      post settings_exports_path

      expect(response.body).to include("run")
      expect(response.body).to include("5000")
      expect(response.body).to include("1800")
    end
  end

  context "when not authenticated" do
    before { delete session_path }

    it "redirects to login" do
      get settings_exports_path
      expect(response).to redirect_to(new_session_path)
    end
  end
end
