describe GeminiClient do
  let(:client) do
    described_class.new(api_key: "test-key", model: "gemini-2.5-flash")
  end

  def mock_response(code, body)
    response = instance_double(Net::HTTPResponse, code: code.to_s, body:)
    http = instance_double(Net::HTTP)
    allow(Net::HTTP).to receive(:new).and_return(http)
    allow(http).to receive(:use_ssl=)
    allow(http).to receive(:open_timeout=)
    allow(http).to receive(:read_timeout=)
    allow(http).to receive(:request).and_return(response)
  end

  describe "#generate" do
    it "returns text from successful response" do
      body = {
        candidates: [{ content: { parts: [{ text: "Generated response" }] } }]
      }.to_json

      mock_response(200, body)
      expect(client.generate("Test prompt")).to eq("Generated response")
    end

    it "raises AuthenticationError on 401" do
      mock_response(401, "Unauthorized")
      expect { client.generate("Test") }.to raise_error(
        GeminiClient::AuthenticationError
      )
    end

    it "raises AuthenticationError on 403" do
      mock_response(403, "Forbidden")
      expect { client.generate("Test") }.to raise_error(
        GeminiClient::AuthenticationError
      )
    end

    it "raises RateLimitError on 429 after retries" do
      mock_response(429, "Too many requests")
      allow(client).to receive(:sleep)
      expect { client.generate("Test") }.to raise_error(
        GeminiClient::RateLimitError
      )
    end

    it "raises Error on other status codes" do
      mock_response(500, "Internal Server Error")
      expect { client.generate("Test") }.to raise_error(
        GeminiClient::Error,
        /500/
      )
    end

    it "raises Error when response format is unexpected" do
      mock_response(200, { candidates: [] }.to_json)
      expect { client.generate("Test") }.to raise_error(
        GeminiClient::Error,
        /no text content/
      )
    end

    context "daily request limit" do
      fixtures :users

      let(:user) { users(:john) }
      let(:log_context) { { user: user, action: "test" } }

      it "raises DailyRequestLimitError when limit is reached" do
        GeminiClient::DAILY_REQUEST_LIMIT.times do |i|
          AiLog.create!(
            user: user,
            action: "test",
            model: "gemini-2.5-flash",
            prompt: "p#{i}"
          )
        end

        expect {
          client.generate("Test", log_context: log_context)
        }.to raise_error(
          GeminiClient::DailyRequestLimitError,
          /Daily AI request limit/
        )
      end

      it "allows requests when under the limit" do
        body = {
          candidates: [{ content: { parts: [{ text: "OK" }] } }]
        }.to_json

        mock_response(200, body)
        expect(client.generate("Test", log_context: log_context)).to eq("OK")
      end

      it "does not enforce limit when no log_context is provided" do
        body = {
          candidates: [{ content: { parts: [{ text: "OK" }] } }]
        }.to_json

        GeminiClient::DAILY_REQUEST_LIMIT.times do |i|
          AiLog.create!(
            user: user,
            action: "test",
            model: "gemini-2.5-flash",
            prompt: "p#{i}"
          )
        end

        mock_response(200, body)
        expect(client.generate("Test")).to eq("OK")
      end
    end

    context "retry with backoff" do
      it "retries and succeeds after transient failure" do
        success_body = {
          candidates: [{ content: { parts: [{ text: "OK" }] } }]
        }.to_json

        http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(http)
        allow(http).to receive(:use_ssl=)
        allow(http).to receive(:open_timeout=)
        allow(http).to receive(:read_timeout=)

        call_count = 0
        allow(http).to receive(:request) do
          call_count += 1
          raise Net::OpenTimeout, "execution expired" if call_count == 1
          instance_double(Net::HTTPResponse, code: "200", body: success_body)
        end
        allow(client).to receive(:sleep)

        expect(client.generate("Test")).to eq("OK")
        expect(call_count).to eq(2)
      end

      it "raises after exhausting retries" do
        http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(http)
        allow(http).to receive(:use_ssl=)
        allow(http).to receive(:open_timeout=)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:request).and_raise(
          Net::ReadTimeout,
          "read timeout"
        )
        allow(client).to receive(:sleep)

        expect { client.generate("Test") }.to raise_error(Net::ReadTimeout)
      end

      it "does not retry authentication errors" do
        mock_response(403, "Forbidden")

        expect { client.generate("Test") }.to raise_error(
          GeminiClient::AuthenticationError
        )
      end
    end
  end

  describe "#generate_chat" do
    let(:messages) do
      [
        { role: "user", text: "Hello" },
        { role: "model", text: "Hi there!" },
        { role: "user", text: "How are you?" }
      ]
    end

    it "returns text from successful response" do
      body = {
        candidates: [{ content: { parts: [{ text: "I'm great!" }] } }]
      }.to_json

      mock_response(200, body)
      expect(client.generate_chat(messages)).to eq("I'm great!")
    end

    it "sends multi-turn contents in request body" do
      body = {
        candidates: [{ content: { parts: [{ text: "Response" }] } }]
      }.to_json

      http = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:use_ssl=)
      allow(http).to receive(:open_timeout=)
      allow(http).to receive(:read_timeout=)

      response = instance_double(Net::HTTPResponse, code: "200", body:)
      allow(http).to receive(:request) do |req|
        parsed = JSON.parse(req.body)
        expect(parsed["contents"]).to eq(
          [
            { "role" => "user", "parts" => [{ "text" => "Hello" }] },
            { "role" => "model", "parts" => [{ "text" => "Hi there!" }] },
            { "role" => "user", "parts" => [{ "text" => "How are you?" }] }
          ]
        )
        response
      end

      client.generate_chat(messages)
    end

    it "includes system_instruction in request body when provided" do
      body = {
        candidates: [{ content: { parts: [{ text: "Response" }] } }]
      }.to_json

      http = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:use_ssl=)
      allow(http).to receive(:open_timeout=)
      allow(http).to receive(:read_timeout=)

      response = instance_double(Net::HTTPResponse, code: "200", body:)
      allow(http).to receive(:request) do |req|
        parsed = JSON.parse(req.body)
        expect(parsed["system_instruction"]).to eq(
          { "parts" => [{ "text" => "You are a trainer." }] }
        )
        response
      end

      client.generate_chat(messages, system_instruction: "You are a trainer.")
    end

    it "omits system_instruction from request body when not provided" do
      body = {
        candidates: [{ content: { parts: [{ text: "Response" }] } }]
      }.to_json

      http = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:use_ssl=)
      allow(http).to receive(:open_timeout=)
      allow(http).to receive(:read_timeout=)

      response = instance_double(Net::HTTPResponse, code: "200", body:)
      allow(http).to receive(:request) do |req|
        parsed = JSON.parse(req.body)
        expect(parsed).not_to have_key("system_instruction")
        response
      end

      client.generate_chat(messages)
    end

    context "with logging" do
      fixtures :users

      it "logs prompt as JSON" do
        user = users(:john)

        body = {
          candidates: [{ content: { parts: [{ text: "OK" }] } }]
        }.to_json

        mock_response(200, body)

        client.generate_chat(
          messages,
          log_context: {
            user: user,
            action: "test_chat"
          }
        )

        log = AiLog.last
        expect(log.action).to eq("test_chat")
        expect(JSON.parse(log.prompt)).to be_an(Array)
      end
    end
  end
end
