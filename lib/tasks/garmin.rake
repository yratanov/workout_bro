namespace :garmin do
  desc "Sync running activities from Garmin Connect"
  task sync: :environment do
    User.find_each do |user|
      credential = user.garmin_credential
      next if credential.username.blank? || credential.encrypted_password.blank?

      puts "Syncing Garmin activities for #{user.email_address}..."

      service = GarminSyncService.new(user: user)
      result = service.call

      puts "Sync complete: #{result[:imported]} imported, #{result[:skipped]} skipped"
    rescue GarminSyncService::Error => e
      puts "Garmin sync failed for #{user.email_address}: #{e.message}"
    end
  end

  desc "Sync running activities from Garmin Connect for a specific user"
  task :sync_user, [ :email ] => :environment do |_t, args|
    email = args[:email] || ENV["EMAIL"]
    raise "Email is required. Usage: rake garmin:sync_user[email@example.com]" if email.blank?

    user = User.find_by!(email_address: email)

    puts "Syncing Garmin activities for #{user.email_address}..."

    service = GarminSyncService.new(user: user)
    result = service.call

    puts "Sync complete: #{result[:imported]} imported, #{result[:skipped]} skipped"
  rescue ActiveRecord::RecordNotFound
    puts "User not found: #{email}"
    exit 1
  rescue GarminSyncService::Error => e
    puts "Garmin sync failed: #{e.message}"
    exit 1
  end
end
