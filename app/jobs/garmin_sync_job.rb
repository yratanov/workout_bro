class GarminSyncJob < ApplicationJob
  queue_as :default

  def perform
    User.find_each do |user|
      credential = user.garmin_credential
      next if credential.username.blank? || credential.encrypted_password.blank? || !credential.sync_enabled?

      Rails.logger.info "Syncing Garmin activities for #{user.email}..."

      service = GarminSyncService.new(user: user)
      result = service.call

      Rails.logger.info "Sync complete: #{result[:imported]} imported, #{result[:skipped]} skipped"
    rescue GarminSyncService::Error => e
      Rails.logger.error "Garmin sync failed for #{user.email}: #{e.message}"
    end
  end
end
