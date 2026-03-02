describe AiClient do
  describe ".for" do
    it "returns a Gemini client for gemini provider" do
      user =
        instance_double(
          User,
          ai_provider: "gemini",
          ai_api_key: "test-key",
          ai_model: "gemini-2.0-flash"
        )

      client = described_class.for(user)

      expect(client).to be_a(AiClients::Gemini)
    end

    it "raises ArgumentError for unknown provider" do
      user = instance_double(User, ai_provider: "openai")

      expect { described_class.for(user) }.to raise_error(
        ArgumentError,
        /Unknown AI provider: openai/
      )
    end
  end
end
