# frozen_string_literal: true

require "net/http"
require "json"

class GeminiClient
  BASE_URL = "https://generativelanguage.googleapis.com/v1beta"

  Error = Class.new(StandardError)
  AuthenticationError = Class.new(Error)
  RateLimitError = Class.new(Error)

  def initialize(api_key:, model:)
    @api_key = api_key
    @model = model
  end

  def generate(prompt)
    uri = URI("#{BASE_URL}/models/#{@model}:generateContent?key=#{@api_key}")
    body = { contents: [{ parts: [{ text: prompt }] }] }

    response = post(uri, body)
    parse_response(response)
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
end
