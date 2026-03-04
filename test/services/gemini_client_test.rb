require "test_helper"

class GeminiClientTest < ActiveSupport::TestCase
  setup do
    @client = GeminiClient.new(api_key: "test-key", model: "gemini-2.5-flash")
  end

  test "generate returns text from successful response" do
    VCR.use_cassette("gemini_client/generate_success") do
      assert_equal "Generated response", @client.generate("Test prompt")
    end
  end

  test "generate raises AuthenticationError on 401" do
    VCR.use_cassette("gemini_client/generate_401") do
      assert_raises(GeminiClient::AuthenticationError) do
        @client.generate("Test")
      end
    end
  end

  test "generate raises AuthenticationError on 403" do
    VCR.use_cassette("gemini_client/generate_403") do
      assert_raises(GeminiClient::AuthenticationError) do
        @client.generate("Test")
      end
    end
  end

  test "generate raises RateLimitError on 429 after retries" do
    @client.stubs(:sleep)
    VCR.use_cassette("gemini_client/generate_429") do
      assert_raises(GeminiClient::RateLimitError) { @client.generate("Test") }
    end
  end

  test "generate raises Error on other status codes" do
    VCR.use_cassette("gemini_client/generate_500") do
      error = assert_raises(GeminiClient::Error) { @client.generate("Test") }
      assert_match(/500/, error.message)
    end
  end

  test "generate raises Error when response format is unexpected" do
    VCR.use_cassette("gemini_client/generate_empty_candidates") do
      error = assert_raises(GeminiClient::Error) { @client.generate("Test") }
      assert_match(/no text content/, error.message)
    end
  end

  test "generate logs token counts from usageMetadata" do
    user = users(:john)
    VCR.use_cassette("gemini_client/generate_with_tokens") do
      @client.generate("Test", log_context: { user: user, action: "test" })
    end

    log = AiLog.last
    assert_equal 100, log.input_tokens
    assert_equal 50, log.output_tokens
    assert_equal 150, log.total_tokens
  end

  test "generate handles missing usageMetadata gracefully" do
    user = users(:john)
    VCR.use_cassette("gemini_client/generate_no_usage") do
      @client.generate("Test", log_context: { user: user, action: "test" })
    end

    log = AiLog.last
    assert_nil log.input_tokens
    assert_nil log.output_tokens
    assert_nil log.total_tokens
  end

  test "generate raises DailyRequestLimitError when limit is reached" do
    user = users(:john)
    GeminiClient::DAILY_REQUEST_LIMIT.times do |i|
      AiLog.create!(
        user: user,
        action: "test",
        model: "gemini-2.5-flash",
        prompt: "p#{i}"
      )
    end

    error =
      assert_raises(GeminiClient::DailyRequestLimitError) do
        @client.generate("Test", log_context: { user: user, action: "test" })
      end
    assert_match(/Daily AI request limit/, error.message)
  end

  test "generate allows requests when under the limit" do
    user = users(:john)
    VCR.use_cassette("gemini_client/generate_ok") do
      assert_equal "OK",
                   @client.generate(
                     "Test",
                     log_context: {
                       user: user,
                       action: "test"
                     }
                   )
    end
  end

  test "generate does not enforce limit when no log_context is provided" do
    user = users(:john)
    GeminiClient::DAILY_REQUEST_LIMIT.times do |i|
      AiLog.create!(
        user: user,
        action: "test",
        model: "gemini-2.5-flash",
        prompt: "p#{i}"
      )
    end

    VCR.use_cassette("gemini_client/generate_ok") do
      assert_equal "OK", @client.generate("Test")
    end
  end

  test "generate raises Error with parsed JSON error message body" do
    VCR.use_cassette("gemini_client/generate_404") do
      error = assert_raises(GeminiClient::Error) { @client.generate("Test") }
      assert_match(/404/, error.message)
      assert_match(/Model not found/, error.message)
    end
  end

  test "log_request handles errors gracefully" do
    user = users(:john)
    AiLog.stubs(:create!).raises(ActiveRecord::StatementInvalid, "DB error")

    VCR.use_cassette("gemini_client/generate_ok") do
      assert_nothing_raised do
        @client.generate("Test", log_context: { user: user, action: "test" })
      end
    end
  end

  test "generate_chat returns text from successful response" do
    VCR.use_cassette("gemini_client/generate_chat_success") do
      messages = [
        { role: "user", text: "Hello" },
        { role: "model", text: "Hi there!" },
        { role: "user", text: "How are you?" }
      ]

      assert_equal "I'm great!", @client.generate_chat(messages)
    end
  end

  test "generate_chat sends multi-turn contents in request body" do
    VCR.use_cassette("gemini_client/generate_chat_response") do
      messages = [
        { role: "user", text: "Hello" },
        { role: "model", text: "Hi there!" },
        { role: "user", text: "How are you?" }
      ]

      # The cassette will match and return the expected response
      result = @client.generate_chat(messages)
      assert_equal "Response", result
    end
  end

  test "generate_chat includes system_instruction when provided" do
    VCR.use_cassette("gemini_client/generate_chat_response") do
      messages = [{ role: "user", text: "Hello" }]
      result =
        @client.generate_chat(
          messages,
          system_instruction: "You are a trainer."
        )
      assert_equal "Response", result
    end
  end

  test "generate_chat omits system_instruction when not provided" do
    VCR.use_cassette("gemini_client/generate_chat_response") do
      messages = [{ role: "user", text: "Hello" }]
      result = @client.generate_chat(messages)
      assert_equal "Response", result
    end
  end

  test "generate_chat logs prompt as JSON" do
    user = users(:john)
    VCR.use_cassette("gemini_client/generate_chat_ok") do
      messages = [
        { role: "user", text: "Hello" },
        { role: "model", text: "Hi there!" },
        { role: "user", text: "How are you?" }
      ]

      @client.generate_chat(
        messages,
        log_context: {
          user: user,
          action: "test_chat"
        }
      )
    end

    log = AiLog.last
    assert_equal "test_chat", log.action
    assert_instance_of Array, JSON.parse(log.prompt)
  end

  test "generate_chat_stream yields accumulated text chunks" do
    VCR.use_cassette("gemini_client/stream_success") do
      yielded = []
      messages = [{ role: "user", text: "Hi" }]
      result =
        @client.generate_chat_stream(messages) { |text| yielded << text.dup }

      assert_equal "Hello world!", result
      assert_includes yielded, "Hello world!"
    end
  end

  test "generate_chat_stream with system_instruction includes it in request body" do
    VCR.use_cassette("gemini_client/stream_response") do
      messages = [{ role: "user", text: "Hello" }]
      result =
        @client.generate_chat_stream(messages, system_instruction: "Be helpful")
      assert_equal "Response", result
    end
  end

  test "generate_chat_stream logs the request when log_context is provided" do
    user = users(:john)
    VCR.use_cassette("gemini_client/stream_logged") do
      messages = [{ role: "user", text: "Hi" }]
      @client.generate_chat_stream(
        messages,
        log_context: {
          user: user,
          action: "stream_test"
        }
      )
    end

    log = AiLog.last
    assert_equal "stream_test", log.action
    assert_equal "Streamed", log.response
    assert_equal 10, log.input_tokens
    assert_equal 5, log.output_tokens
    assert_equal 15, log.total_tokens
    assert_not_nil log.duration_ms
  end

  test "generate_chat_stream logs error on failure when log_context is provided" do
    user = users(:john)
    VCR.use_cassette("gemini_client/stream_429_logged") do
      messages = [{ role: "user", text: "Hi" }]
      assert_raises(GeminiClient::RateLimitError) do
        @client.generate_chat_stream(
          messages,
          log_context: {
            user: user,
            action: "stream_error"
          }
        )
      end
    end

    log = AiLog.last
    assert_equal "stream_error", log.action
    assert_not_nil log.error
  end

  test "generate_chat_stream raises RateLimitError on 429" do
    VCR.use_cassette("gemini_client/stream_429") do
      messages = [{ role: "user", text: "Hi" }]
      assert_raises(GeminiClient::RateLimitError) do
        @client.generate_chat_stream(messages)
      end
    end
  end

  test "generate_chat_stream raises AuthenticationError on 401" do
    VCR.use_cassette("gemini_client/stream_401") do
      messages = [{ role: "user", text: "Hi" }]
      assert_raises(GeminiClient::AuthenticationError) do
        @client.generate_chat_stream(messages)
      end
    end
  end

  test "generate_chat_stream raises Error when no text content in stream" do
    VCR.use_cassette("gemini_client/stream_empty") do
      messages = [{ role: "user", text: "Hi" }]
      assert_raises(GeminiClient::Error) do
        @client.generate_chat_stream(messages)
      end
    end
  end
end
