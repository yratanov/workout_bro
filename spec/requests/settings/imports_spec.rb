describe "Settings::Imports" do
  fixtures :all

  let(:user) { users(:john) }

  before { sign_in(user) }

  describe "GET /settings/imports" do
    it "returns success" do
      get settings_imports_path
      expect(response).to have_http_status(:success)
    end

    it "displays the import form" do
      get settings_imports_path
      expect(response.body).to include("Import Workouts")
    end

    context "with existing imports" do
      it "displays import history" do
        get settings_imports_path
        expect(response.body).to include("test.csv")
        expect(response.body).to include("Imported: 5")
      end
    end
  end

  describe "POST /settings/imports" do
    let(:csv_content) { <<~CSV }
        2024-01-15,,,,
        Bench Press,60x10,70x8,,
      CSV

    let(:csv_file) do
      Rack::Test::UploadedFile.new(
        StringIO.new(csv_content),
        "text/csv",
        original_filename: "workouts.csv"
      )
    end

    it "creates a new import" do
      expect {
        post settings_imports_path,
             params: {
               workout_import: {
                 file: csv_file,
                 original_filename: "workouts.csv"
               }
             }
      }.to change(WorkoutImport, :count).by(1)
    end

    it "enqueues the import job" do
      expect {
        post settings_imports_path,
             params: {
               workout_import: {
                 file: csv_file,
                 original_filename: "workouts.csv"
               }
             }
      }.to have_enqueued_job(WorkoutImportJob)
    end

    it "redirects with success message" do
      post settings_imports_path,
           params: {
             workout_import: {
               file: csv_file,
               original_filename: "workouts.csv"
             }
           }

      expect(response).to redirect_to(settings_imports_path)
      follow_redirect!
      expect(response.body).to include("Import started")
    end
  end

  describe "GET /settings/imports/:id/status" do
    let(:workout_import) { workout_imports(:completed) }

    it "returns import status as JSON" do
      get status_settings_imports_path(workout_import.id)

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("application/json")

      json = JSON.parse(response.body)
      expect(json["status"]).to eq("completed")
      expect(json["imported_count"]).to eq(5)
      expect(json["skipped_count"]).to eq(2)
    end

    context "with failed import" do
      let(:failed_import) { workout_imports(:failed) }

      it "includes error details" do
        get status_settings_imports_path(failed_import.id)

        json = JSON.parse(response.body)
        expect(json["status"]).to eq("failed")
        expect(json["error_details"]["message"]).to eq("Test error")
      end
    end

    context "when import belongs to another user" do
      let(:other_import) { workout_imports(:other_user_import) }

      it "returns not found" do
        get status_settings_imports_path(other_import.id)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /settings/imports/:id" do
    let(:workout_import) { workout_imports(:completed) }

    let!(:imported_workouts) do
      [
        user.workouts.create!(
          workout_type: :strength,
          started_at: 1.day.ago,
          ended_at: 1.day.ago + 1.hour,
          workout_import: workout_import
        ),
        user.workouts.create!(
          workout_type: :strength,
          started_at: 2.days.ago,
          ended_at: 2.days.ago + 1.hour,
          workout_import: workout_import
        )
      ]
    end

    it "deletes the import and its workouts" do
      expect {
        delete import_settings_imports_path(workout_import.id)
      }.to change(WorkoutImport, :count).by(-1).and change(Workout, :count).by(
              -2
            )
    end

    it "redirects with success message" do
      delete import_settings_imports_path(workout_import.id)

      expect(response).to redirect_to(settings_imports_path)
      follow_redirect!
      expect(response.body).to include("2 workouts deleted")
    end

    context "when import belongs to another user" do
      let(:other_import) { workout_imports(:other_user_import) }

      it "returns not found" do
        delete import_settings_imports_path(other_import.id)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  context "when not authenticated" do
    before { delete session_path }

    it "redirects to login" do
      get settings_imports_path
      expect(response).to redirect_to(new_session_path)
    end
  end
end
