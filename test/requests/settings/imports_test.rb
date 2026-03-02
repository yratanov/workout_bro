require "test_helper"

class Settings::ImportsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
    sign_in(@user)
  end

  test "GET /settings/imports returns success" do
    get settings_imports_path
    assert_response :success
  end

  test "GET /settings/imports displays the import form" do
    get settings_imports_path
    assert_includes response.body, "Import Workouts"
  end

  test "GET /settings/imports displays import history" do
    get settings_imports_path
    assert_includes response.body, "test.csv"
    assert_includes response.body, "Imported: 5"
  end

  test "POST /settings/imports creates a new import" do
    assert_difference "WorkoutImport.count", 1 do
      post settings_imports_path,
           params: {
             workout_import: {
               file: csv_file,
               original_filename: "workouts.csv"
             }
           }
    end
  end

  test "POST /settings/imports enqueues the import job" do
    assert_enqueued_with(job: WorkoutImportJob) do
      post settings_imports_path,
           params: {
             workout_import: {
               file: csv_file,
               original_filename: "workouts.csv"
             }
           }
    end
  end

  test "POST /settings/imports redirects with success message" do
    post settings_imports_path,
         params: {
           workout_import: {
             file: csv_file,
             original_filename: "workouts.csv"
           }
         }
    assert_redirected_to settings_imports_path
    follow_redirect!
    assert_includes response.body, "Import started"
  end

  test "GET /settings/imports/:id/status returns import status as JSON" do
    workout_import = workout_imports(:completed)
    get status_settings_imports_path(workout_import.id)
    assert_response :success
    assert_includes response.content_type, "application/json"

    json = JSON.parse(response.body)
    assert_equal "completed", json["status"]
    assert_equal 5, json["imported_count"]
    assert_equal 2, json["skipped_count"]
  end

  test "GET /settings/imports/:id/status includes error details for failed import" do
    failed_import = workout_imports(:failed)
    get status_settings_imports_path(failed_import.id)

    json = JSON.parse(response.body)
    assert_equal "failed", json["status"]
    assert_equal "Test error", json["error_details"]["message"]
  end

  test "GET /settings/imports/:id/status returns not found for other user's import" do
    other_import = workout_imports(:other_user_import)
    get status_settings_imports_path(other_import.id)
    assert_response :not_found
  end

  test "DELETE /settings/imports/:id deletes the import and its workouts" do
    workout_import = workout_imports(:completed)
    imported_workouts = [
      @user.workouts.create!(
        workout_type: :strength,
        started_at: 1.day.ago,
        ended_at: 1.day.ago + 1.hour,
        workout_import: workout_import
      ),
      @user.workouts.create!(
        workout_type: :strength,
        started_at: 2.days.ago,
        ended_at: 2.days.ago + 1.hour,
        workout_import: workout_import
      )
    ]

    assert_difference "WorkoutImport.count", -1 do
      assert_difference "Workout.count", -2 do
        delete import_settings_imports_path(workout_import.id)
      end
    end
  end

  test "DELETE /settings/imports/:id redirects with success message" do
    workout_import = workout_imports(:completed)
    @user.workouts.create!(
      workout_type: :strength,
      started_at: 1.day.ago,
      ended_at: 1.day.ago + 1.hour,
      workout_import: workout_import
    )
    @user.workouts.create!(
      workout_type: :strength,
      started_at: 2.days.ago,
      ended_at: 2.days.ago + 1.hour,
      workout_import: workout_import
    )

    delete import_settings_imports_path(workout_import.id)
    assert_redirected_to settings_imports_path
    follow_redirect!
    assert_includes response.body, "2 workouts deleted"
  end

  test "DELETE /settings/imports/:id returns not found for other user's import" do
    other_import = workout_imports(:other_user_import)
    delete import_settings_imports_path(other_import.id)
    assert_response :not_found
  end

  test "GET /settings/imports redirects to login when not authenticated" do
    delete session_path
    get settings_imports_path
    assert_redirected_to new_session_path
  end

  private

  def csv_file
    csv_content = <<~CSV
      2024-01-15,,,,
      Bench Press,60x10,70x8,,
    CSV
    Rack::Test::UploadedFile.new(
      StringIO.new(csv_content),
      "text/csv",
      original_filename: "workouts.csv"
    )
  end
end
