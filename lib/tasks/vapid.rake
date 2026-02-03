namespace :vapid do
  desc "Generate VAPID keys for Web Push notifications"
  task generate: :environment do
    keys = WebPush.generate_key

    puts "Add these keys to your Rails credentials (bin/rails credentials:edit):"
    puts
    puts "vapid:"
    puts "  public_key: \"#{keys.public_key}\""
    puts "  private_key: \"#{keys.private_key}\""
    puts "  subject: \"mailto:admin@workout-bro.com\""
    puts
    puts "IMPORTANT: Keep the private_key secret! The public_key will be shared with browsers."
  end
end
