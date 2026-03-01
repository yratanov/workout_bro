# frozen_string_literal: true

require "net/http"
require "json"

class GeminiClient
  BASE_URL = "https://generativelanguage.googleapis.com/v1beta"

  DAILY_REQUEST_LIMIT = 10

  Error = Class.new(StandardError)
  AuthenticationError = Class.new(Error)
  RateLimitError = Class.new(Error)
  DailyRequestLimitError = Class.new(Error)

  def initialize(api_key:, model:)
    @api_key = api_key
    @model = model
  end

  def generate(prompt, log_context: nil)
    enforce_daily_limit!(log_context)
    uri = URI("#{BASE_URL}/models/#{@model}:generateContent?key=#{@api_key}")
    body = { contents: [{ parts: [{ text: prompt }] }] }

    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    response = post(uri, body)
    result = parse_response(response)
    duration_ms =
      (
        (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000
      ).round

    if log_context
      log_request(
        prompt:,
        response_text: result,
        duration_ms:,
        context: log_context
      )
    end
    result
  rescue => e
    duration_ms =
      (
        (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000
      ).round if start_time
    if log_context
      log_request(prompt:, error: e.message, duration_ms:, context: log_context)
    end
    raise
  end

  private

  def post(uri, body)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 120

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = body.to_json

    http.request(request)
  end

  def parse_response(response)
    case response.code.to_i
    when 200
      data = JSON.parse(response.body)
      extract_text(data)
    when 401, 403
      raise AuthenticationError, "Invalid API key or unauthorized access"
    when 429
      raise RateLimitError, "API rate limit exceeded. Please try again later."
    else
      raise Error, "API request failed (#{response.code}): #{response.body}"
    end
  end

  def extract_text(data)
    data.dig("candidates", 0, "content", "parts", 0, "text") ||
      raise(Error, "Unexpected response format: no text content found")
  end

  def enforce_daily_limit!(log_context)
    user = log_context&.dig(:user)
    return unless user

    count = AiLog.where(user: user, created_at: Date.current.all_day).count
    return unless count >= DAILY_REQUEST_LIMIT

    raise DailyRequestLimitError,
          "Daily AI request limit (#{DAILY_REQUEST_LIMIT}) reached. Try again tomorrow."
  end

  def log_request(
    prompt:,
    response_text: nil,
    error: nil,
    duration_ms: nil,
    context: nil
  )
    return unless context&.dig(:user) && context&.dig(:action)

    AiLog.create!(
      user: context[:user],
      action: context[:action],
      model: @model,
      prompt:,
      response: response_text,
      error:,
      duration_ms:
    )
  rescue => e
    Rails.logger.error("Failed to log AI request: #{e.message}")
  end
end
