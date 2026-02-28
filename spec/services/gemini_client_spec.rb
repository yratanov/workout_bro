describe GeminiClient do
  let(:client) { described_class.new(api_key: "test-key", model: "gemini-2.5-flash") }

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
        candidates: [{
          content: { parts: [{ text: "Generated response" }] }
        }]
      }.to_json

      mock_response(200, body)
      expect(client.generate("Test prompt")).to eq("Generated response")
    end

    it "raises AuthenticationError on 401" do
      mock_response(401, "Unauthorized")
      expect { client.generate("Test") }.to raise_error(GeminiClient::AuthenticationError)
    end

    it "raises AuthenticationError on 403" do
      mock_response(403, "Forbidden")
      expect { client.generate("Test") }.to raise_error(GeminiClient::AuthenticationError)
    end

    it "raises RateLimitError on 429" do
      mock_response(429, "Too many requests")
      expect { client.generate("Test") }.to raise_error(GeminiClient::RateLimitError)
    end

    it "raises Error on other status codes" do
      mock_response(500, "Internal Server Error")
      expect { client.generate("Test") }.to raise_error(GeminiClient::Error, /500/)
    end

    it "raises Error when response format is unexpected" do
      mock_response(200, { candidates: [] }.to_json)
      expect { client.generate("Test") }.to raise_error(GeminiClient::Error, /no text content/)
    end
  end
end
