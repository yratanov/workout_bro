class StravaSyncJob < ApplicationJob
  queue_as :default

  def perform
    User.find_each do |user|
      credential = user.strava_credential
      next unless credential.oauth_configured? && credential.sync_enabled?

      Rails.logger.info "Syncing Strava activities for #{user.email}..."

      service = StravaSyncService.new(user: user)
      result = service.call

      Rails.logger.info "Sync complete: #{result[:imported]} imported, #{result[:skipped]} skipped"
    rescue StravaSyncService::Error => e
      Rails.logger.error "Strava sync failed for #{user.email}: #{e.message}"
    end
  end
end
