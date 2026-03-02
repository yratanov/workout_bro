require "test_helper"

class ErrorReporterMiddlewareTest < ActiveSupport::TestCase
  setup { @env = Rack::MockRequest.env_for("/") }

  test "passes through normal requests" do
    app = ->(_env) { [200, {}, ["ok"]] }
    middleware = ErrorReporterMiddleware.new(app)

    status, _headers, body = middleware.call(@env)

    assert_equal 200, status
    assert_equal ["ok"], body
  end

  test "catches exceptions and logs them via ErrorLogger then re-raises" do
    error = RuntimeError.new("something went wrong")
    app = ->(_env) { raise error }
    middleware = ErrorReporterMiddleware.new(app)

    ErrorLogger.expects(:log).with(
      error,
      source: "controller",
      context: anything
    )

    assert_raises(RuntimeError) { middleware.call(@env) }
  end

  test "does not catch SystemStackError" do
    app = ->(_env) { raise SystemStackError, "stack level too deep" }
    middleware = ErrorReporterMiddleware.new(app)

    ErrorLogger.expects(:log).never

    assert_raises(SystemStackError) { middleware.call(@env) }
  end

  test "does not catch NoMemoryError" do
    app = ->(_env) { raise NoMemoryError, "out of memory" }
    middleware = ErrorReporterMiddleware.new(app)

    ErrorLogger.expects(:log).never

    assert_raises(NoMemoryError) { middleware.call(@env) }
  end

  test "includes request context in the log" do
    error = StandardError.new("test error")
    app = ->(_env) { raise error }
    middleware = ErrorReporterMiddleware.new(app)

    logged_context = nil
    ErrorLogger
      .stubs(:log)
      .with do |_err, opts|
        logged_context = opts[:context]
        true
      end

    assert_raises(StandardError) { middleware.call(@env) }

    assert logged_context.key?(:path)
    assert logged_context.key?(:method)
    assert logged_context.key?(:url)
    assert_equal "/", logged_context[:path]
    assert_equal "GET", logged_context[:method]
  end
end
