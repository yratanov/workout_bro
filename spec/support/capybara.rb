require 'capybara/rspec'

Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless=new')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-gpu')
  options.add_argument('--window-size=1400,1400')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.javascript_driver = :headless_chrome
Capybara.default_max_wait_time = 5

RSpec.configure do |config|
  config.before(:each, type: :feature) do
    Capybara.current_driver = :headless_chrome
  end

  config.after(:each, type: :feature) do
    Capybara.reset_sessions!
  end
end
