require "test_helper"

class Settings::ExportsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
    sign_in(@user)
  end

  test "GET /settings/exports returns success" do
    get settings_exports_path
    assert_response :success
  end

  test "GET /settings/exports displays the export page" do
    get settings_exports_path
    assert_includes response.body, "Export Workouts"
  end

  test "GET /settings/exports shows workout and exercise counts" do
    get settings_exports_path
    assert_includes response.body, "Completed Workouts"
    assert_includes response.body, "Exercises"
  end

  test "POST /settings/exports returns a CSV file" do
    post settings_exports_path
    assert_response :success
    assert_includes response.content_type, "text/csv"
  end

  test "POST /settings/exports sets the correct filename" do
    post settings_exports_path
    assert_includes response.headers["Content-Disposition"],
                    "workout_bro_export_"
    assert_includes response.headers["Content-Disposition"], ".csv"
  end

  test "POST /settings/exports includes CSV headers" do
    post settings_exports_path
    csv_lines = response.body.lines
    headers = csv_lines.first.strip.split(",")
    assert_includes headers, "date"
    assert_includes headers, "workout_type"
    assert_includes headers, "exercise_name"
    assert_includes headers, "weight"
    assert_includes headers, "reps"
  end

  test "POST /settings/exports includes strength workout data" do
    post settings_exports_path
    assert_includes response.body, "strength"
    assert_includes response.body, "Bench Press"
  end

  test "POST /settings/exports includes run workout data" do
    post settings_exports_path
    assert_includes response.body, "run"
    assert_includes response.body, "5000"
    assert_includes response.body, "1800"
  end

  test "GET /settings/exports redirects to login when not authenticated" do
    delete session_path
    get settings_exports_path
    assert_redirected_to new_session_path
  end
end
