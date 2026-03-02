require "test_helper"

# == Schema Information
#
# Table name: error_logs
# Database name: primary
#
#  id          :integer          not null, primary key
#  backtrace   :json
#  context     :json
#  error_class :string           not null
#  message     :text
#  severity    :integer          default("error"), not null
#  source      :string           default("application")
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  request_id  :string
#
# Indexes
#
#  index_error_logs_on_created_at  (created_at)
#  index_error_logs_on_severity    (severity)
#

class ErrorLogTest < ActiveSupport::TestCase
  test "is valid with valid attributes" do
    error_log =
      ErrorLog.new(
        error_class: "StandardError",
        message: "Test error",
        severity: :error
      )
    assert error_log.valid?
  end

  test "requires error_class" do
    error_log = ErrorLog.new(message: "Test error", severity: :error)
    assert_not error_log.valid?
    assert_includes error_log.errors[:error_class], "can't be blank"
  end

  test "requires severity" do
    error_log =
      ErrorLog.new(
        error_class: "StandardError",
        message: "Test error",
        severity: nil
      )
    assert_not error_log.valid?
  end

  test "defines severity enum" do
    assert_equal(
      { "error" => 0, "warning" => 1, "info" => 2 },
      ErrorLog.severities
    )
  end

  test "allows setting severity to error" do
    error_log = ErrorLog.new(severity: :error)
    assert error_log.error?
  end

  test "allows setting severity to warning" do
    error_log = ErrorLog.new(severity: :warning)
    assert error_log.warning?
  end

  test "allows setting severity to info" do
    error_log = ErrorLog.new(severity: :info)
    assert error_log.info?
  end

  test "recent scope orders by created_at descending" do
    old_log =
      ErrorLog.create!(
        error_class: "Old",
        severity: :error,
        created_at: 1.hour.ago
      )
    new_log =
      ErrorLog.create!(
        error_class: "New",
        severity: :error,
        created_at: Time.current
      )

    assert_equal new_log, ErrorLog.recent.first
    assert_equal old_log, ErrorLog.recent.last
  end

  test "defaults severity to error" do
    error_log = ErrorLog.new(error_class: "Test")
    assert_equal "error", error_log.severity
  end

  test "defaults source to application" do
    error_log = ErrorLog.create!(error_class: "Test", severity: :error)
    assert_equal "application", error_log.source
  end

  test "stores backtrace as array" do
    error_log =
      ErrorLog.create!(
        error_class: "StandardError",
        severity: :error,
        backtrace: %w[/app/file.rb:1 /app/file.rb:2]
      )
    error_log.reload
    assert_equal %w[/app/file.rb:1 /app/file.rb:2], error_log.backtrace
  end

  test "stores context as hash" do
    error_log =
      ErrorLog.create!(
        error_class: "StandardError",
        severity: :error,
        context: {
          user_id: 1,
          action: "test"
        }
      )
    error_log.reload
    assert_equal({ "user_id" => 1, "action" => "test" }, error_log.context)
  end
end
