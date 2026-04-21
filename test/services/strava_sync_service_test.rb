require "test_helper"

class StravaSyncServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @user = users(:john)
    @user.strava_credential.update!(
      access_token: "test_access_token",
      refresh_token: "test_refresh_token",
      token_expires_at: 1.hour.from_now
    )
    @service = StravaSyncService.new(user: @user)
  end

  test "raises MissingCredentialsError when not connected" do
    @user.strava_credential.update_columns(
      access_token: nil,
      refresh_token: nil
    )
    @user.reload
    service = StravaSyncService.new(user: @user)

    assert_raises(StravaSyncService::MissingCredentialsError) { service.call }
  end

  test "creates run workouts for each activity" do
    stub_strava_api(strava_activities_json)

    assert_difference "Workout.count", 2 do
      @service.call
    end
  end

  test "returns import statistics" do
    stub_strava_api(strava_activities_json)

    result = @service.call
    assert_equal({ imported: 2, skipped: 0 }, result)
  end

  test "creates workouts with correct attributes" do
    stub_strava_api(strava_activities_json)
    @service.call

    workout =
      Workout.find_by(started_at: Time.zone.parse("2024-01-15T08:30:00"))
    assert_equal @user, workout.user
    assert_equal "run", workout.workout_type
    assert_equal 5000, workout.distance
    assert_equal 1800, workout.time_in_seconds # moving_time (excludes pauses)
    assert_equal 156, workout.avg_heart_rate
    assert_equal 178, workout.max_heart_rate
    assert_equal 170, workout.avg_cadence # Strava cadence doubled
    assert_in_delta 45.2, workout.elevation_gain
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

    stub_strava_api([strava_activities_json.first].to_json)

    assert_no_difference "Workout.count" do
      @service.call
    end
  end

  test "skips non-running activities" do
    cycling_activity = [
      {
        type: "Ride",
        sport_type: "Ride",
        start_date_local: "2024-01-15T08:30:00Z",
        distance: 20_000,
        moving_time: 3600,
        elapsed_time: 3700
      }
    ].to_json

    stub_strava_api(cycling_activity)

    assert_no_difference "Workout.count" do
      @service.call
    end
  end

  test "doubles strava cadence for total steps per minute" do
    stub_strava_api(strava_activities_json)
    @service.call

    workout =
      Workout.find_by(started_at: Time.zone.parse("2024-01-15T08:30:00"))
    # Strava reports 85 (single leg), we store 170 (total)
    assert_equal 170, workout.avg_cadence
  end

  test "refreshes token when expired" do
    @user.strava_credential.update!(token_expires_at: 1.minute.ago)
    service = StravaSyncService.new(user: @user.reload)

    StravaOauthService.any_instance.expects(:refresh_token!)

    stub_strava_api([].to_json)

    service.call
  end

  test "does not refresh token when not expired" do
    StravaOauthService.any_instance.expects(:refresh_token!).never

    stub_strava_api([].to_json)

    @service.call
  end

  test "raises RateLimitedError when recent 429 failure exists" do
    @user.sync_logs.create!(
      log_type: :strava,
      status: :failure,
      message: "Strava API 429: Too Many Requests"
    )

    error = assert_raises(StravaSyncService::RateLimitedError) { @service.call }
    assert_includes error.message, "rate-limited"
  end

  test "allows sync when 429 failure is older than cooldown period" do
    @user.sync_logs.create!(
      log_type: :strava,
      status: :failure,
      message: "Strava API 429: Too Many Requests",
      created_at: 25.hours.ago
    )
    stub_strava_api([].to_json)

    result = @service.call
    assert_equal({ imported: 0, skipped: 0 }, result)
  end

  test "logs success to sync_logs" do
    stub_strava_api([].to_json)

    assert_difference "SyncLog.count", 1 do
      @service.call
    end

    log = @user.sync_logs.last
    assert_equal "strava", log.log_type
    assert_equal "success", log.status
  end

  test "logs failure to sync_logs" do
    stub_strava_api_error(429)

    assert_difference "SyncLog.count", 1 do
      assert_raises(StravaSyncService::RateLimitedError) { @service.call }
    end

    log = @user.sync_logs.last
    assert_equal "strava", log.log_type
    assert_equal "failure", log.status
  end

  test "enqueues AI feedback job when user has AI configured" do
    @user.update!(
      ai_provider: "gemini",
      ai_model: "gemini-2.0-flash",
      ai_api_key: "test-key"
    )
    stub_strava_api(strava_activities_json)

    assert_enqueued_with(job: GenerateAiWorkoutFeedbackJob) { @service.call }
  end

  test "does not enqueue AI feedback job when user has no AI configured" do
    stub_strava_api(strava_activities_json)

    assert_no_enqueued_jobs(only: GenerateAiWorkoutFeedbackJob) do
      @service.call
    end
  end

  private

  def strava_activities_json
    [
      {
        type: "Run",
        sport_type: "Run",
        start_date_local: "2024-01-15T08:30:00Z",
        distance: 5000.0,
        moving_time: 1800,
        elapsed_time: 1850,
        average_heartrate: 156.0,
        max_heartrate: 178.0,
        average_cadence: 85.0,
        total_elevation_gain: 45.2
      },
      {
        type: "Run",
        sport_type: "Run",
        start_date_local: "2024-01-16T07:00:00Z",
        distance: 10_000.0,
        moving_time: 3600,
        elapsed_time: 3650
      }
    ].to_json
  end

  def stub_strava_api(json_response)
    response = Net::HTTPSuccess.new("1.1", "200", "OK")
    response.stubs(:body).returns(json_response)
    Net::HTTP.any_instance.stubs(:request).returns(response)
  end

  def stub_strava_api_error(code)
    response_class =
      case code
      when 429
        Net::HTTPTooManyRequests
      when 401
        Net::HTTPUnauthorized
      else
        Net::HTTPInternalServerError
      end

    response = response_class.new("1.1", code.to_s, "Error")
    response.stubs(:body).returns("{}")
    Net::HTTP.any_instance.stubs(:request).returns(response)
  end
end
