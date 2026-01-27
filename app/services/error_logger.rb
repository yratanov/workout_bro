# frozen_string_literal: true

class ErrorLogger
  THREAD_KEY = :error_logger_active

  class << self
    def log(error, source:, context: {})
      return if Thread.current[THREAD_KEY]

      Thread.current[THREAD_KEY] = true

      ErrorLog.insert({
        error_class: error.class.name.to_s[0, 255],
        message: error.message.to_s[0, 10_000],
        severity: 0,
        source: source.to_s[0, 255],
        backtrace: safe_json(error.backtrace&.first(20)),
        context: safe_json(context),
        request_id: context[:request_id].to_s[0, 255],
        created_at: Time.current,
        updated_at: Time.current
      })
    rescue Exception # rubocop:disable Lint/RescueException
      # Silently fail - can't safely log errors about logging
    ensure
      Thread.current[THREAD_KEY] = false
    end

    private

    def safe_json(obj)
      return nil if obj.nil?

      obj.to_json
    rescue StandardError
      nil
    end
  end
end
