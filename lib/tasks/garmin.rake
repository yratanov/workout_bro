namespace :garmin do
  desc "Sync running activities from Garmin Connect"
  task sync: :environment do
    username = ENV.fetch("GARMIN_USERNAME") { raise "GARMIN_USERNAME is required" }
    password = ENV.fetch("GARMIN_PASSWORD") { raise "GARMIN_PASSWORD is required" }

    puts "Starting Garmin sync..."

    service = GarminSyncService.new(username: username, password: password)
    result = service.call

    puts "Sync complete: #{result[:imported]} imported, #{result[:skipped]} skipped"
  rescue GarminSyncService::Error => e
    puts "Garmin sync failed: #{e.message}"
    exit 1
  end
end
