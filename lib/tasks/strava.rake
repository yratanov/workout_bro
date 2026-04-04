namespace :strava do
  desc "Sync running activities from Strava"
  task sync: :environment do
    User.find_each do |user|
      credential = user.strava_credential
      next unless credential.oauth_configured?

      puts "Syncing Strava activities for #{user.email}..."

      service = StravaSyncService.new(user: user)
      result = service.call

      puts "Sync complete: #{result[:imported]} imported, #{result[:skipped]} skipped"
    rescue StravaSyncService::Error => e
      puts "Strava sync failed for #{user.email}: #{e.message}"
    end
  end

  desc "Sync running activities from Strava for a specific user"
  task :sync_user, [:email] => :environment do |_t, args|
    email = args[:email] || ENV["EMAIL"]
    if email.blank?
      raise "Email is required. Usage: rake strava:sync_user[email@example.com]"
    end

    user = User.find_by!(email: email)

    puts "Syncing Strava activities for #{user.email}..."

    service = StravaSyncService.new(user: user)
    result = service.call

    puts "Sync complete: #{result[:imported]} imported, #{result[:skipped]} skipped"
  rescue ActiveRecord::RecordNotFound
    puts "User not found: #{email}"
    exit 1
  rescue StravaSyncService::Error => e
    puts "Strava sync failed: #{e.message}"
    exit 1
  end
end
