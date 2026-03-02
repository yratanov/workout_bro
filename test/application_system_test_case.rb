require "test_helper"
require "capybara/minitest"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include Capybara::Minitest::Assertions
  include LoginHelpers

  driven_by :headless_chrome

  Capybara.register_driver :headless_chrome do |app|
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument("--headless=new")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-gpu")
    options.add_argument("--window-size=1400,1400")

    Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
  end

  Capybara.default_max_wait_time = 5
end
