require "simplecov"
SimpleCov.start "rails" do
  add_filter "/test/"
  add_filter "/config/"
  add_filter "/db/"
  add_filter "/vendor/"
  enable_coverage :branch

  at_exit do
    next unless SimpleCov.command_name == "Minitest"

    SimpleCov.result.format!

    puts "\n\n#{"-" * 80}"
    puts "Coverage: #{SimpleCov.result.covered_percent.round(2)}% " \
           "(#{SimpleCov.result.covered_lines}/#{SimpleCov.result.total_lines} lines)"
    puts "#{"-" * 80}"

    least_covered =
      SimpleCov
        .result
        .files
        .sort_by(&:covered_percent)
        .first(20)
        .reject { |f| f.covered_percent == 100 }

    if least_covered.any?
      puts "\nLeast covered files:"
      puts "#{"File".ljust(70)} Coverage"
      puts "-" * 80
      least_covered.each do |file|
        short = file.filename.sub("#{SimpleCov.root}/", "")
        puts "#{short.ljust(70)} #{file.covered_percent.round(1)}%"
      end
    end

    puts
  end
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"
require "webmock/minitest"

# Allow localhost connections for system tests and dev server
WebMock.disable_net_connect!(allow_localhost: true)

# Require support files
Rails.root.glob("test/support/**/*.rb").sort_by(&:to_s).each { |f| require f }

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)

    parallelize_setup do |worker|
      SimpleCov.command_name "#{SimpleCov.command_name}-#{worker}"
    end

    parallelize_teardown { SimpleCov.result }

    fixtures :all
  end
end
