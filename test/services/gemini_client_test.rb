require "test_helper"

class GeminiClientTest < ActiveSupport::TestCase
  setup do
    @client = GeminiClient.new(api_key: "test-key", model: "gemini-2.5-flash")
  end

  test "generate returns text from successful response" do
    body = {
      candidates: [{ content: { parts: [{ text: "Generated response" }] } }],
      usageMetadata: {
        promptTokenCount: 10,
        candidatesTokenCount: 20,
        totalTokenCount: 30
      }
    }.to_json

    stub_http_response(200, body)
    assert_equal "Generated response", @client.generate("Test prompt")
  end

  test "generate raises AuthenticationError on 401" do
    stub_http_response(401, "Unauthorized")
    assert_raises(GeminiClient::AuthenticationError) do
      @client.generate("Test")
    end
  end

  test "generate raises AuthenticationError on 403" do
    stub_http_response(403, "Forbidden")
    assert_raises(GeminiClient::AuthenticationError) do
      @client.generate("Test")
    end
  end

  test "generate raises RateLimitError on 429 after retries" do
    stub_http_response(429, "Too many requests")
    @client.stubs(:sleep)
    assert_raises(GeminiClient::RateLimitError) { @client.generate("Test") }
  end

  test "generate raises Error on other status codes" do
    stub_http_response(500, "Internal Server Error")
    error = assert_raises(GeminiClient::Error) { @client.generate("Test") }
    assert_match(/500/, error.message)
  end

  test "generate raises Error when response format is unexpected" do
    stub_http_response(200, { candidates: [] }.to_json)
    error = assert_raises(GeminiClient::Error) { @client.generate("Test") }
    assert_match(/no text content/, error.message)
  end

  test "generate logs token counts from usageMetadata" do
    user = users(:john)
    body = {
      candidates: [{ content: { parts: [{ text: "OK" }] } }],
      usageMetadata: {
        promptTokenCount: 100,
        candidatesTokenCount: 50,
        totalTokenCount: 150
      }
    }.to_json

    stub_http_response(200, body)
    @client.generate("Test", log_context: { user: user, action: "test" })

    log = AiLog.last
    assert_equal 100, log.input_tokens
    assert_equal 50, log.output_tokens
    assert_equal 150, log.total_tokens
  end

  test "generate handles missing usageMetadata gracefully" do
    user = users(:john)
    body = { candidates: [{ content: { parts: [{ text: "OK" }] } }] }.to_json

    stub_http_response(200, body)
    @client.generate("Test", log_context: { user: user, action: "test" })

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
    body = { candidates: [{ content: { parts: [{ text: "OK" }] } }] }.to_json
    stub_http_response(200, body)

    assert_equal "OK",
                 @client.generate(
                   "Test",
                   log_context: {
                     user: user,
                     action: "test"
                   }
                 )
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

    body = { candidates: [{ content: { parts: [{ text: "OK" }] } }] }.to_json
    stub_http_response(200, body)

    assert_equal "OK", @client.generate("Test")
  end

  test "generate retries and succeeds after transient failure" do
    success_body = {
      candidates: [{ content: { parts: [{ text: "OK" }] } }]
    }.to_json
    success_response = stub(code: "200", body: success_body)

    http = stub("Net::HTTP")
    Net::HTTP.stubs(:new).returns(http)
    http.stubs(:use_ssl=)
    http.stubs(:open_timeout=)
    http.stubs(:read_timeout=)

    call_count = 0
    http.define_singleton_method(:request) do |*|
      call_count += 1
      raise Net::OpenTimeout, "execution expired" if call_count == 1
      success_response
    end
    @client.stubs(:sleep)

    assert_equal "OK", @client.generate("Test")
    assert_equal 2, call_count
  end

  test "generate raises after exhausting retries" do
    http = mock("Net::HTTP")
    Net::HTTP.stubs(:new).returns(http)
    http.stubs(:use_ssl=)
    http.stubs(:open_timeout=)
    http.stubs(:read_timeout=)
    http.stubs(:request).raises(Net::ReadTimeout, "read timeout")
    @client.stubs(:sleep)

    assert_raises(Net::ReadTimeout) { @client.generate("Test") }
  end

  test "generate does not retry authentication errors" do
    stub_http_response(403, "Forbidden")
    assert_raises(GeminiClient::AuthenticationError) do
      @client.generate("Test")
    end
  end

  test "generate_chat returns text from successful response" do
    body = {
      candidates: [{ content: { parts: [{ text: "I'm great!" }] } }]
    }.to_json
    stub_http_response(200, body)

    messages = [
      { role: "user", text: "Hello" },
      { role: "model", text: "Hi there!" },
      { role: "user", text: "How are you?" }
    ]

    assert_equal "I'm great!", @client.generate_chat(messages)
  end

  test "generate_chat sends multi-turn contents in request body" do
    body = {
      candidates: [{ content: { parts: [{ text: "Response" }] } }]
    }.to_json

    http = mock("Net::HTTP")
    Net::HTTP.stubs(:new).returns(http)
    http.stubs(:use_ssl=)
    http.stubs(:open_timeout=)
    http.stubs(:read_timeout=)

    http
      .expects(:request)
      .with do |req|
        parsed = JSON.parse(req.body)
        parsed["contents"] ==
          [
            { "role" => "user", "parts" => [{ "text" => "Hello" }] },
            { "role" => "model", "parts" => [{ "text" => "Hi there!" }] },
            { "role" => "user", "parts" => [{ "text" => "How are you?" }] }
          ]
      end
      .returns(stub(code: "200", body: body))

    messages = [
      { role: "user", text: "Hello" },
      { role: "model", text: "Hi there!" },
      { role: "user", text: "How are you?" }
    ]
    @client.generate_chat(messages)
  end

  test "generate_chat includes system_instruction when provided" do
    body = {
      candidates: [{ content: { parts: [{ text: "Response" }] } }]
    }.to_json

    http = mock("Net::HTTP")
    Net::HTTP.stubs(:new).returns(http)
    http.stubs(:use_ssl=)
    http.stubs(:open_timeout=)
    http.stubs(:read_timeout=)

    http
      .expects(:request)
      .with do |req|
        parsed = JSON.parse(req.body)
        parsed["system_instruction"] ==
          { "parts" => [{ "text" => "You are a trainer." }] }
      end
      .returns(stub(code: "200", body: body))

    messages = [{ role: "user", text: "Hello" }]
    @client.generate_chat(messages, system_instruction: "You are a trainer.")
  end

  test "generate_chat omits system_instruction when not provided" do
    body = {
      candidates: [{ content: { parts: [{ text: "Response" }] } }]
    }.to_json

    http = mock("Net::HTTP")
    Net::HTTP.stubs(:new).returns(http)
    http.stubs(:use_ssl=)
    http.stubs(:open_timeout=)
    http.stubs(:read_timeout=)

    http
      .expects(:request)
      .with do |req|
        parsed = JSON.parse(req.body)
        !parsed.key?("system_instruction")
      end
      .returns(stub(code: "200", body: body))

    messages = [{ role: "user", text: "Hello" }]
    @client.generate_chat(messages)
  end

  test "generate_chat logs prompt as JSON" do
    user = users(:john)
    body = { candidates: [{ content: { parts: [{ text: "OK" }] } }] }.to_json
    stub_http_response(200, body)

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

    log = AiLog.last
    assert_equal "test_chat", log.action
    assert_instance_of Array, JSON.parse(log.prompt)
  end

  test "generate_chat_stream yields accumulated text chunks" do
    chunks = [
      sse_data(
        {
          "candidates" => [
            { "content" => { "parts" => [{ "text" => "Hello" }] } }
          ]
        }
      ),
      sse_data(
        {
          "candidates" => [
            { "content" => { "parts" => [{ "text" => " world" }] } }
          ]
        }
      ),
      sse_data(
        {
          "candidates" => [{ "content" => { "parts" => [{ "text" => "!" }] } }],
          "usageMetadata" => {
            "promptTokenCount" => 5,
            "candidatesTokenCount" => 3,
            "totalTokenCount" => 8
          }
        }
      )
    ].join

    stub_streaming_response(200, chunks)

    yielded = []
    messages = [{ role: "user", text: "Hi" }]
    result =
      @client.generate_chat_stream(messages) { |text| yielded << text.dup }

    assert_equal "Hello world!", result
    assert_equal "Hello", yielded[0]
    assert_equal "Hello world", yielded[1]
    assert_equal "Hello world!", yielded[2]
  end

  test "generate_chat_stream with system_instruction includes it in request body" do
    chunks =
      sse_data(
        {
          "candidates" => [
            { "content" => { "parts" => [{ "text" => "Response" }] } }
          ],
          "usageMetadata" => {
            "promptTokenCount" => 5,
            "candidatesTokenCount" => 3,
            "totalTokenCount" => 8
          }
        }
      )

    captured_body = nil
    stub_streaming_response(200, chunks) do |req|
      captured_body = JSON.parse(req.body)
    end

    messages = [{ role: "user", text: "Hello" }]
    @client.generate_chat_stream(messages, system_instruction: "Be helpful")

    assert_equal(
      { "parts" => [{ "text" => "Be helpful" }] },
      captured_body["system_instruction"]
    )
  end

  test "generate_chat_stream logs the request when log_context is provided" do
    user = users(:john)
    chunks =
      sse_data(
        {
          "candidates" => [
            { "content" => { "parts" => [{ "text" => "Streamed" }] } }
          ],
          "usageMetadata" => {
            "promptTokenCount" => 10,
            "candidatesTokenCount" => 5,
            "totalTokenCount" => 15
          }
        }
      )
    stub_streaming_response(200, chunks)

    messages = [{ role: "user", text: "Hi" }]
    @client.generate_chat_stream(
      messages,
      log_context: {
        user: user,
        action: "stream_test"
      }
    )

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
    stub_streaming_response(429, "Too many requests")

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

    log = AiLog.last
    assert_equal "stream_error", log.action
    assert_not_nil log.error
  end

  test "generate_chat_stream raises RateLimitError on 429" do
    stub_streaming_response(429, "Rate limited")

    messages = [{ role: "user", text: "Hi" }]
    assert_raises(GeminiClient::RateLimitError) do
      @client.generate_chat_stream(messages)
    end
  end

  test "generate_chat_stream raises AuthenticationError on 401" do
    stub_streaming_response(401, "Unauthorized")

    messages = [{ role: "user", text: "Hi" }]
    assert_raises(GeminiClient::AuthenticationError) do
      @client.generate_chat_stream(messages)
    end
  end

  test "generate_chat_stream raises Error when no text content in stream" do
    chunks = sse_data({ "candidates" => [] })
    stub_streaming_response(200, chunks)

    messages = [{ role: "user", text: "Hi" }]
    assert_raises(GeminiClient::Error) do
      @client.generate_chat_stream(messages)
    end
  end

  test "generate raises Error with parsed JSON error message body" do
    error_body = { "error" => { "message" => "Model not found" } }.to_json
    stub_http_response(404, error_body)

    error = assert_raises(GeminiClient::Error) { @client.generate("Test") }
    assert_match(/404/, error.message)
    assert_match(/Model not found/, error.message)
  end

  test "log_request handles errors gracefully" do
    user = users(:john)
    AiLog.stubs(:create!).raises(ActiveRecord::StatementInvalid, "DB error")

    body = { candidates: [{ content: { parts: [{ text: "OK" }] } }] }.to_json
    stub_http_response(200, body)

    # Should not raise despite AiLog.create! failing
    assert_nothing_raised do
      @client.generate("Test", log_context: { user: user, action: "test" })
    end
  end

  private

  def stub_http_response(code, body)
    response = stub(code: code.to_s, body: body)
    http = stub(request: response)
    http.stubs(:use_ssl=)
    http.stubs(:open_timeout=)
    http.stubs(:read_timeout=)
    Net::HTTP.stubs(:new).returns(http)
  end

  def sse_data(hash)
    "data: #{hash.to_json}\n\n"
  end

  def stub_streaming_response(code, body_content, &request_callback)
    http = Object.new

    class << http
      attr_accessor :use_ssl, :open_timeout, :read_timeout
    end

    http.define_singleton_method(:use_ssl=) { |v| }
    http.define_singleton_method(:open_timeout=) { |v| }
    http.define_singleton_method(:read_timeout=) { |v| }

    http.define_singleton_method(:request) do |req, &block|
      request_callback&.call(req)

      response = Object.new
      response.define_singleton_method(:code) { code.to_s }

      if code == 200
        response.define_singleton_method(:read_body) do |&chunk_block|
          chunk_block.call(body_content)
        end
      else
        response.define_singleton_method(:read_body) { body_content }
      end

      block.call(response)
    end

    Net::HTTP.stubs(:new).returns(http)
  end
end
