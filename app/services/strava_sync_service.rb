class StravaSyncService
  API_BASE = "https://www.strava.com/api/v3".freeze
  RATE_LIMIT_COOLDOWN = 24.hours

  class Error < StandardError
  end
  class MissingCredentialsError < Error
  end
  class RateLimitedError < Error
  end
  class TokenRefreshError < Error
  end

  def initialize(user:, days: 7)
    @user = user
    @days = days
    @credential = user.strava_credential
  end

  def call
    validate_credentials!
    check_rate_limit_cooldown!
    refresh_token_if_needed!
    activities = fetch_activities
    result = import_activities(activities)
    log_success(result)
    result
  rescue Error => e
    log_failure(e.message)
    raise
  end

  private

  def validate_credentials!
    unless @credential.oauth_configured?
      raise MissingCredentialsError, "Strava not connected"
    end
  end

  def check_rate_limit_cooldown!
    last_rate_limit =
      @user
        .sync_logs
        .where(log_type: :strava, status: :failure)
        .where("message LIKE ?", "%429%")
        .order(created_at: :desc)
        .first

    return unless last_rate_limit
    return if last_rate_limit.created_at < RATE_LIMIT_COOLDOWN.ago

    retry_after = last_rate_limit.created_at + RATE_LIMIT_COOLDOWN
    raise RateLimitedError,
          "Strava rate-limited. Next sync allowed after #{retry_after.strftime("%Y-%m-%d %H:%M %Z")}"
  end

  def refresh_token_if_needed!
    return unless @credential.token_expired?

    StravaOauthService.new.refresh_token!(@credential)
    @credential.reload
  rescue StravaOauthService::Error => e
    raise TokenRefreshError, "Failed to refresh Strava token: #{e.message}"
  end

  def fetch_activities
    uri = URI("#{API_BASE}/athlete/activities")
    uri.query = URI.encode_www_form(after: @days.days.ago.to_i, per_page: 200)

    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{@credential.access_token}"

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    response = http.request(request)
    handle_response(response, uri)
  end

  def handle_response(response, uri)
    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    elsif response.is_a?(Net::HTTPUnauthorized)
      refresh_and_retry!(uri)
    elsif response.is_a?(Net::HTTPTooManyRequests)
      raise RateLimitedError, "Strava API 429: Too Many Requests"
    else
      raise Error, "Strava API error: #{response.code} #{response.message}"
    end
  end

  def refresh_and_retry!(uri)
    StravaOauthService.new.refresh_token!(@credential)
    @credential.reload

    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{@credential.access_token}"

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      raise Error, "Strava API error after token refresh: #{response.code}"
    end

    JSON.parse(response.body)
  rescue StravaOauthService::Error => e
    raise TokenRefreshError, "Failed to refresh Strava token: #{e.message}"
  end

  def import_activities(activities)
    imported = 0
    skipped = 0
    new_workouts = []

    activities.each do |activity|
      next unless running_activity?(activity)

      started_at = Time.zone.parse(activity["start_date_local"])
      next unless started_at

      if workout_exists?(started_at)
        skipped += 1
        next
      end

      workout = create_workout(activity, started_at)
      new_workouts << workout
      imported += 1
    end

    enqueue_ai_feedback(new_workouts)

    { imported: imported, skipped: skipped }
  end

  def running_activity?(activity)
    %w[Run TrailRun].include?(activity["type"]) ||
      %w[Run TrailRun].include?(activity["sport_type"])
  end

  def workout_exists?(started_at)
    Workout.exists?(started_at: started_at, workout_type: :run)
  end

  def create_workout(activity, started_at)
    elapsed_seconds = activity["elapsed_time"].to_i
    moving_seconds = activity["moving_time"].to_i
    ended_at =
      elapsed_seconds.positive? ? started_at + elapsed_seconds.seconds : nil

    Workout.create!(
      user: @user,
      workout_type: :run,
      date: started_at.to_date,
      started_at: started_at,
      ended_at: ended_at,
      distance: activity["distance"].to_f.round,
      time_in_seconds: moving_seconds,
      avg_heart_rate: activity["average_heartrate"]&.to_i,
      max_heart_rate: activity["max_heartrate"]&.to_i,
      avg_cadence: strava_cadence(activity["average_cadence"]),
      elevation_gain: activity["total_elevation_gain"]&.to_f
    )
  end

  def strava_cadence(cadence)
    return nil if cadence.nil?

    # Strava reports single-leg cadence; double it for total steps/min
    (cadence.to_f * 2).round
  end

  def enqueue_ai_feedback(workouts)
    return unless @user.ai_configured? && @user.ai_trainer

    workouts.each do |workout|
      GenerateAiWorkoutFeedbackJob.perform_later(workout: workout)
    end
  end

  def log_success(result)
    @user.sync_logs.create!(
      log_type: :strava,
      status: :success,
      message: "Imported #{result[:imported]}, skipped #{result[:skipped]}",
      metadata: result
    )
  end

  def log_failure(error_message)
    @user.sync_logs.create!(
      log_type: :strava,
      status: :failure,
      message: error_message
    )
  end
end
