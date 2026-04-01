require "test_helper"

class GarminSyncServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @user = users(:john)
    @username = "test@example.com"
    @password = "secret123"
    @user.garmin_credential.update!(username: @username, password: @password)
    @service = GarminSyncService.new(user: @user)
  end

  test "raises MissingCredentialsError when credentials are missing" do
    @user.garmin_credential.update_columns(
      username: nil,
      encrypted_password: nil
    )
    @user.reload
    service = GarminSyncService.new(user: @user)

    assert_raises(GarminSyncService::MissingCredentialsError) { service.call }
  end

  test "creates run workouts for each activity" do
    stub_python_script(activities_json)

    assert_difference "Workout.count", 2 do
      @service.call
    end
  end

  test "returns import statistics" do
    stub_python_script(activities_json)

    result = @service.call
    assert_equal({ imported: 2, skipped: 0 }, result)
  end

  test "creates workouts with correct attributes" do
    stub_python_script(activities_json)
    @service.call

    workout =
      Workout.find_by(started_at: Time.zone.parse("2024-01-15T08:30:00"))
    assert_equal @user, workout.user
    assert_equal "run", workout.workout_type
    assert_equal 5000, workout.distance
    assert_equal 1800, workout.time_in_seconds
    assert_equal workout.started_at + 1800.seconds, workout.ended_at
  end

  test "calls Python script with credentials from database" do
    stub_python_script(activities_json)

    Open3
      .expects(:capture3)
      .with(
        "python3",
        GarminSyncService::PYTHON_SCRIPT_PATH,
        @username,
        @password,
        "7"
      )
      .returns([activities_json, "", stub(success?: true, exitstatus: 0)])

    @service.call
  end

  test "skips existing activities" do
    Workout.create!(
      user: @user,
      workout_type: :run,
      date: Time.zone.parse("2024-01-15T08:30:00").to_date,
      started_at: Time.zone.parse("2024-01-15T08:30:00"),
      ended_at: Time.zone.parse("2024-01-15T08:30:00") + 30.minutes,
      distance: 5000,
      time_in_seconds: 1800
    )

    single_activity_json = {
      activities: [
        {
          started_at: "2024-01-15T08:30:00",
          distance_meters: 5000,
          duration_seconds: 1800
        }
      ]
    }.to_json
    stub_python_script(single_activity_json)

    assert_no_difference "Workout.count" do
      @service.call
    end
  end

  test "returns correct statistics when skipping existing activities" do
    Workout.create!(
      user: @user,
      workout_type: :run,
      date: Time.zone.parse("2024-01-15T08:30:00").to_date,
      started_at: Time.zone.parse("2024-01-15T08:30:00"),
      ended_at: Time.zone.parse("2024-01-15T08:30:00") + 30.minutes,
      distance: 5000,
      time_in_seconds: 1800
    )

    single_activity_json = {
      activities: [
        {
          started_at: "2024-01-15T08:30:00",
          distance_meters: 5000,
          duration_seconds: 1800
        }
      ]
    }.to_json
    stub_python_script(single_activity_json)

    result = @service.call
    assert_equal({ imported: 0, skipped: 1 }, result)
  end

  test "raises error when Python script fails" do
    Open3.stubs(:capture3).returns(
      ["", "some error", stub(success?: false, exitstatus: 1)]
    )

    assert_raises(GarminSyncService::Error) { @service.call }
  end

  test "raises error with message when Python returns error" do
    error_json = { error: "Invalid credentials" }.to_json
    Open3.stubs(:capture3).returns(
      [error_json, "", stub(success?: true, exitstatus: 0)]
    )

    error = assert_raises(GarminSyncService::Error) { @service.call }
    assert_equal "Invalid credentials", error.message
  end

  test "returns zero imports when Python returns empty activities" do
    empty_json = { activities: [] }.to_json
    stub_python_script(empty_json)

    result = @service.call
    assert_equal({ imported: 0, skipped: 0 }, result)
  end

  test "enqueues AI feedback job when user has AI configured" do
    @user.update!(
      ai_provider: "gemini",
      ai_model: "gemini-2.0-flash",
      ai_api_key: "test-key"
    )
    stub_python_script(activities_json)

    assert_enqueued_with(job: GenerateAiWorkoutFeedbackJob) { @service.call }
  end

  test "does not enqueue AI feedback job when user has no AI configured" do
    stub_python_script(activities_json)

    assert_no_enqueued_jobs(only: GenerateAiWorkoutFeedbackJob) do
      @service.call
    end
  end

  test "raises RateLimitedError when recent 429 failure exists" do
    @user.sync_logs.create!(
      log_type: :garmin,
      status: :failure,
      message: "Error in request: 429 Client Error: Too Many Requests"
    )

    error = assert_raises(GarminSyncService::RateLimitedError) { @service.call }
    assert_includes error.message, "rate-limited"
  end

  test "allows sync when 429 failure is older than cooldown period" do
    @user.sync_logs.create!(
      log_type: :garmin,
      status: :failure,
      message: "Error in request: 429 Client Error: Too Many Requests",
      created_at: 25.hours.ago
    )
    stub_python_script({ activities: [] }.to_json)

    result = @service.call
    assert_equal({ imported: 0, skipped: 0 }, result)
  end

  test "passes custom days to Python script" do
    service = GarminSyncService.new(user: @user, days: 14)
    empty_json = { activities: [] }.to_json

    Open3
      .expects(:capture3)
      .with(
        "python3",
        GarminSyncService::PYTHON_SCRIPT_PATH,
        @username,
        @password,
        "14"
      )
      .returns([empty_json, "", stub(success?: true, exitstatus: 0)])

    service.call
  end

  private

  def activities_json
    {
      activities: [
        {
          started_at: "2024-01-15T08:30:00",
          distance_meters: 5000,
          duration_seconds: 1800
        },
        {
          started_at: "2024-01-16T07:00:00",
          distance_meters: 10_000,
          duration_seconds: 3600
        }
      ]
    }.to_json
  end

  def stub_python_script(json_output)
    Open3.stubs(:capture3).returns(
      [json_output, "", stub(success?: true, exitstatus: 0)]
    )
  end
end
