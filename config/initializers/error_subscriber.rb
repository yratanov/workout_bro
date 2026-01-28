# frozen_string_literal: true

class ErrorSubscriber
  def report(error, handled:, severity:, context:, source: nil)
    # Skip if ErrorLogger will handle it (avoid duplicates from middleware)
    return if source == "controller"

    ErrorLogger.log(
      error,
      source: source || "application",
      context: context || {}
    )
  end
end

Rails.error.subscribe(ErrorSubscriber.new)
