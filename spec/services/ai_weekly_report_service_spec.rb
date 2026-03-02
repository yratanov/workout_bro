describe AiWeeklyReportService do
  fixtures :all

  let(:user) do
    users(:john).tap do |u|
      u.update!(
        ai_provider: "gemini",
        ai_model: "gemini-2.0-flash",
        ai_api_key: "test-key"
      )
    end
  end

  let(:ai_trainer) do
    user.ai_trainer.tap do |t|
      t.update!(status: :completed, trainer_profile: "A motivational trainer.")
    end
  end

  let(:week_start) { Date.current.beginning_of_week }

  before { ai_trainer }

  describe "#call" do
    it "calls generate_chat with conversation messages when trainer is configured" do
      mock_client = instance_double(GeminiClient)
      allow(GeminiClient).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:generate_chat).and_return("Weekly report")

      result = described_class.new(user, week_start).call

      expect(result).to eq("Weekly report")
      expect(mock_client).to have_received(:generate_chat) do |messages, **|
        expect(messages).to be_an(Array)
        last_msg = messages.last
        expect(last_msg[:role]).to eq("user")
        expect(last_msg[:text]).to include("Training Week")
        expect(last_msg[:text]).to include("weekly overview")
      end
    end

    it "falls back to generate for unconfigured trainer" do
      ai_trainer.update!(status: :pending)

      mock_client = instance_double(GeminiClient)
      allow(GeminiClient).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:generate).and_return("Basic report")

      result = described_class.new(user, week_start).call

      expect(result).to eq("Basic report")
      expect(mock_client).to have_received(:generate)
    end
  end
end
