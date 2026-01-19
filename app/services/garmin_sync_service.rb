class GarminSyncService
  PYTHON_SCRIPT_PATH = Rails.root.join("python/sync_garmin.py").to_s

  class Error < StandardError; end
  class MissingCredentialsError < Error; end

  def initialize(user:, days: 7)
    @user = user
    @days = days
    @credential = user.garmin_credential
  end

  def call
    validate_credentials!
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
    if @credential.username.blank? || @credential.encrypted_password.blank?
      raise MissingCredentialsError, "Garmin credentials not configured"
    end
  end

  def fetch_activities
    output, status = Open3.capture2(
      "python3", PYTHON_SCRIPT_PATH, @credential.username, @credential.encrypted_password, @days.to_s
    )

    raise Error, "Python script failed with status #{status.exitstatus}" unless status.success?

    result = JSON.parse(output)

    raise Error, result["error"] if result["error"]

    result["activities"] || []
  end

  def import_activities(activities)
    imported = 0
    skipped = 0

    activities.each do |activity|
      started_at = Time.zone.parse(activity["started_at"])
      next unless started_at

      if workout_exists?(started_at)
        skipped += 1
        next
      end

      create_workout(activity, started_at)
      imported += 1
    end

    { imported: imported, skipped: skipped }
  end

  def workout_exists?(started_at)
    Workout.exists?(started_at: started_at, workout_type: :run)
  end

  def create_workout(activity, started_at)
    duration_seconds = activity["duration_seconds"].to_i
    ended_at = duration_seconds.positive? ? started_at + duration_seconds.seconds : nil

    Workout.create!(
      user: @user,
      workout_type: :run,
      date: started_at.to_date,
      started_at: started_at,
      ended_at: ended_at,
      distance: activity["distance_meters"].to_i,
      time_in_seconds: duration_seconds
    )
  end

  def log_success(result)
    @user.sync_logs.create!(
      log_type: :garmin,
      status: :success,
      message: "Imported #{result[:imported]}, skipped #{result[:skipped]}",
      metadata: result
    )
  end

  def log_failure(error_message)
    @user.sync_logs.create!(
      log_type: :garmin,
      status: :failure,
      message: error_message
    )
  end
end
