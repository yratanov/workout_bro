# frozen_string_literal: true

require "net/http"
require "json"

module AiClients
  class Gemini < Base
    BASE_URL = "https://generativelanguage.googleapis.com/v1beta"

    DAILY_REQUEST_LIMIT = 20
    MAX_RETRIES = 2
    RETRY_BASE_DELAY = 2

    RETRYABLE_ERRORS = [
      RateLimitError,
      Net::OpenTimeout,
      Net::ReadTimeout,
      Errno::ECONNRESET
    ].freeze

    def initialize(api_key:, model:)
      @api_key = api_key
      @model = model
    end

    def generate(prompt, generation_config: nil, log_context: nil)
      body = { contents: [{ parts: [{ text: prompt }] }] }
      body[:generationConfig] = generation_config if generation_config
      execute_request(body, prompt_for_log: prompt, log_context:)
    end

    def generate_chat(
      messages,
      system_instruction: nil,
      generation_config: nil,
      log_context: nil
    )
      body = build_chat_body(messages, system_instruction:, generation_config:)
      execute_request(
        body,
        prompt_for_log: chat_prompt_for_log(messages, system_instruction),
        log_context:
      )
    end

    def generate_chat_stream(
      messages,
      system_instruction: nil,
      generation_config: nil,
      log_context: nil,
      &block
    )
      enforce_daily_limit!(log_context)

      body = build_chat_body(messages, system_instruction:, generation_config:)

      uri = build_uri(:streamGenerateContent)
      uri.query = "#{uri.query}&alt=sse"

      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result = stream_post(uri, body, &block)

      if log_context
        log_request(
          prompt: chat_prompt_for_log(messages, system_instruction),
          response_text: result[:text],
          duration_ms: elapsed_ms(start_time),
          context: log_context,
          tokens: result[:tokens]
        )
      end
      result[:text]
    rescue => e
      if log_context
        log_request(
          prompt: chat_prompt_for_log(messages, system_instruction),
          error: e.message,
          duration_ms: (elapsed_ms(start_time) if start_time),
          context: log_context
        )
      end
      raise
    end

    EMBEDDING_MODEL = "gemini-embedding-001"
    EMBEDDING_DIMENSIONS = 768

    def generate_embedding(text, log_context: nil)
      uri =
        URI(
          "#{BASE_URL}/models/#{EMBEDDING_MODEL}:embedContent?key=#{@api_key}"
        )
      body = {
        content: {
          parts: [{ text: text }]
        },
        outputDimensionality: EMBEDDING_DIMENSIONS
      }

      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      response = post(uri, body)

      case response.code.to_i
      when 200
        data = JSON.parse(response.body)
        values = data.dig("embedding", "values")
        raise Error, "No embedding values in response" unless values

        if log_context
          log_request(
            prompt: "embed: #{text.truncate(200)}",
            response_text: "(embedding #{values.length} dims)",
            duration_ms: elapsed_ms(start_time),
            context: log_context
          )
        end
        values
      when 429
        raise RateLimitError, "Embedding rate limit exceeded"
      else
        raise Error,
              "Embedding request failed (#{response.code}): #{response.body}"
      end
    end

    private

    def chat_prompt_for_log(messages, system_instruction)
      log = []
      log << { system_instruction: system_instruction } if system_instruction
      (log + messages).to_json
    end

    def build_chat_body(
      messages,
      system_instruction: nil,
      generation_config: nil
    )
      contents =
        messages.map do |msg|
          { role: msg[:role], parts: [{ text: msg[:text] }] }
        end
      body = { contents: }
      if system_instruction
        body[:system_instruction] = { parts: [{ text: system_instruction }] }
      end
      body[:generationConfig] = generation_config if generation_config
      body
    end

    def execute_request(body, prompt_for_log:, log_context:)
      enforce_daily_limit!(log_context)
      uri = build_uri(:generateContent)
      retries = 0

      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      begin
        response = post(uri, body)
        parsed = parse_response(response)
      rescue *RETRYABLE_ERRORS
        if retries < MAX_RETRIES
          retries += 1
          sleep(RETRY_BASE_DELAY**retries)
          retry
        end
        raise
      end

      if log_context
        log_request(
          prompt: prompt_for_log,
          response_text: parsed[:text],
          duration_ms: elapsed_ms(start_time),
          context: log_context,
          tokens: parsed[:tokens]
        )
      end
      parsed[:text]
    rescue => e
      if log_context
        log_request(
          prompt: prompt_for_log,
          error: e.message,
          duration_ms: (elapsed_ms(start_time) if start_time),
          context: log_context
        )
      end
      raise
    end

    def build_uri(action)
      URI("#{BASE_URL}/models/#{@model}:#{action}?key=#{@api_key}")
    end

    def elapsed_ms(start_time)
      (
        (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000
      ).round
    end

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

    def stream_post(uri, body)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 10
      http.read_timeout = 120

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request["Accept"] = "text/event-stream"
      request.body = body.to_json

      accumulated = +""
      tokens = {}

      http.request(request) do |response|
        case response.code.to_i
        when 200
          response.read_body do |chunk|
            chunk.each_line do |line|
              line = line.strip
              next unless line.start_with?("data: ")

              json_str = line.delete_prefix("data: ")
              next if json_str.empty?

              begin
                data = JSON.parse(json_str)
                text = data.dig("candidates", 0, "content", "parts", 0, "text")
                if text
                  accumulated << text
                  yield accumulated if block_given?
                end
                tokens = extract_token_counts(data) if data.key?(
                  "usageMetadata"
                )
              rescue JSON::ParserError
                next
              end
            end
          end
        when 401, 403
          raise AuthenticationError, "Invalid API key or unauthorized access"
        when 429
          raise RateLimitError,
                "API rate limit exceeded. Please try again later."
        else
          raise Error,
                "API request failed (#{response.code}): #{response.read_body}"
        end
      end

      if accumulated.empty?
        raise Error, "Unexpected response format: no text content found"
      end

      { text: accumulated, tokens: }
    end

    def parse_response(response)
      case response.code.to_i
      when 200
        data = JSON.parse(response.body)
        text = extract_text(data)
        tokens = extract_token_counts(data)
        { text:, tokens: }
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

    def extract_token_counts(data)
      metadata = data["usageMetadata"]
      return {} unless metadata

      {
        input_tokens: metadata["promptTokenCount"],
        output_tokens: metadata["candidatesTokenCount"],
        total_tokens: metadata["totalTokenCount"]
      }
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
      context: nil,
      tokens: nil
    )
      return unless context&.dig(:user) && context&.dig(:action)

      AiLog.create!(
        user: context[:user],
        action: context[:action],
        model: @model,
        prompt:,
        response: response_text,
        error:,
        duration_ms:,
        input_tokens: tokens&.dig(:input_tokens),
        output_tokens: tokens&.dig(:output_tokens),
        total_tokens: tokens&.dig(:total_tokens)
      )
    rescue => e
      Rails.logger.error("Failed to log AI request: #{e.message}")
    end
  end
end
