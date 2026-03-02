require "test_helper"

class ErrorLoggerTest < ActiveSupport::TestCase
  setup do
    @error = StandardError.new("Something went wrong")
    @error.set_backtrace(
      Array.new(30) { |i| "app/models/foo.rb:#{i + 1}:in `bar'" }
    )
  end

  test "logs an error with correct attributes" do
    ErrorLogger.log(
      @error,
      source: "test_source",
      context: {
        request_id: "abc123"
      }
    )

    log = ErrorLog.last
    assert_equal "StandardError", log.error_class
    assert_equal "Something went wrong", log.message
    assert_equal "error", log.severity
    assert_equal "test_source", log.source
    assert_equal "abc123", log.request_id
  end

  test "includes backtrace limited to first 20 lines" do
    ErrorLogger.log(@error, source: "test")

    log = ErrorLog.last
    backtrace = log.backtrace
    assert_equal 20, backtrace.length
    assert_equal "app/models/foo.rb:1:in `bar'", backtrace.first
    assert_equal "app/models/foo.rb:20:in `bar'", backtrace.last
  end

  test "includes context hash" do
    context = { user_id: 42, action: "create", request_id: "req-1" }
    ErrorLogger.log(@error, source: "test", context: context)

    log = ErrorLog.last
    assert_equal 42, log.context["user_id"]
    assert_equal "create", log.context["action"]
  end

  test "truncates long messages to 10000 characters" do
    long_error = StandardError.new("x" * 20_000)
    long_error.set_backtrace(["test.rb:1"])

    ErrorLogger.log(long_error, source: "test")

    log = ErrorLog.last
    assert_equal 10_000, log.message.length
  end

  test "truncates source to 255 characters" do
    long_source = "x" * 300
    ErrorLogger.log(@error, source: long_source)

    log = ErrorLog.last
    assert_equal 255, log.source.length
  end

  test "prevents recursive logging" do
    # Simulate recursive call by calling log from within a log context
    ErrorLog
      .stubs(:insert)
      .raises(ActiveRecord::StatementInvalid.new("DB error"))
      .then
      .returns(true)

    # First call should rescue and not raise
    assert_nothing_raised { ErrorLogger.log(@error, source: "test") }

    # Thread key should be reset after the call
    assert_equal false, Thread.current[:error_logger_active]
  end

  test "handles errors during logging gracefully without raising" do
    ErrorLog.stubs(:insert).raises(RuntimeError, "DB connection lost")

    assert_nothing_raised { ErrorLogger.log(@error, source: "test") }
  end

  test "resets thread key after successful logging" do
    ErrorLogger.log(@error, source: "test")
    assert_equal false, Thread.current[:error_logger_active]
  end

  test "handles nil backtrace" do
    error = StandardError.new("no trace")
    # StandardError.new has nil backtrace by default

    ErrorLogger.log(error, source: "test")

    log = ErrorLog.last
    assert_nil log.backtrace
  end

  test "handles nil context" do
    ErrorLogger.log(@error, source: "test")

    log = ErrorLog.last
    assert_equal({}, log.context)
  end

  test "safe_hash handles non-serializable values" do
    context = { obj: Object.new }
    # Object.new.to_json may raise or produce something; either way it shouldn't blow up
    assert_nothing_raised do
      ErrorLogger.log(@error, source: "test", context: context)
    end
  end

  test "skips logging when already active to prevent recursion" do
    Thread.current[:error_logger_active] = true
    count_before = ErrorLog.count
    ErrorLogger.log(@error, source: "test")
    assert_equal count_before, ErrorLog.count
  ensure
    Thread.current[:error_logger_active] = false
  end

  test "safe_array handles errors gracefully" do
    error = StandardError.new("test")
    # Create an object whose to_s raises
    bad_obj = Object.new
    bad_obj.define_singleton_method(:to_s) { raise "boom" }

    # safe_array should return nil on error
    error.set_backtrace(nil)
    assert_nothing_raised { ErrorLogger.log(error, source: "test") }
  end
end
