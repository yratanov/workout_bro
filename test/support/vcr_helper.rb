# frozen_string_literal: true

require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "test/cassettes"
  config.hook_into :webmock
  config.default_cassette_options = {
    record: ENV["VCR_RECORD"] ? :new_episodes : :none,
    match_requests_on: %i[method uri]
  }

  # Filter sensitive data from cassettes.
  # Uses the literal API key value so VCR applies the same filter
  # to both cassette data and incoming requests (enabling URI matching).
  config.filter_sensitive_data("<GEMINI_API_KEY>") { "test-key" }

  # Allow localhost connections for system tests / dev server
  config.ignore_localhost = true
end
