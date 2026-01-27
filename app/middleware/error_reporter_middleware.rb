# frozen_string_literal: true

class ErrorReporterMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  rescue SystemStackError, NoMemoryError
    raise
  rescue Exception => e # rubocop:disable Lint/RescueException
    ErrorLogger.log(e, source: "controller", context: request_context(env))
    raise
  end

  private

  def request_context(env)
    request = ActionDispatch::Request.new(env)
    {
      request_id: env["action_dispatch.request_id"],
      path: request.path,
      url: request.url[0, 2000],
      method: request.method,
      controller: env["action_dispatch.request.path_parameters"]&.dig(:controller),
      action: env["action_dispatch.request.path_parameters"]&.dig(:action),
      params: filtered_params(request),
      user_agent: request.user_agent&.[](0, 500),
      ip: request.remote_ip
    }
  end

  def filtered_params(request)
    request.filtered_parameters.except(:controller, :action).presence
  rescue StandardError
    nil
  end
end
