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

    it "raises RateLimitError on 429" do
      mock_response(429, "Too many requests")
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
  end
end
