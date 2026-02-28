describe AiCompactionService do
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
      t.update!(
        status: :completed,
        trainer_profile: "A balanced fitness trainer."
      )
    end
  end

  describe "#call" do
    it "calls GeminiClient and returns result" do
      mock_client = instance_double(GeminiClient)
      allow(GeminiClient).to receive(:new).with(
        api_key: "test-key",
        model: "gemini-2.0-flash"
      ).and_return(mock_client)
      allow(mock_client).to receive(:generate).and_return("Compacted review")

      result = described_class.new(ai_trainer).call

      expect(result).to eq("Compacted review")
      expect(mock_client).to have_received(:generate) do |prompt|
        expect(prompt).to include("Trainer Profile")
        expect(prompt).to include("updated comprehensive training review")
      end
    end

    it "includes previous full review in prompt" do
      mock_client = instance_double(GeminiClient)
      allow(GeminiClient).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:generate).and_return("Review")

      described_class.new(ai_trainer).call

      expect(mock_client).to have_received(:generate) do |prompt|
        expect(prompt).to include("Previous Training Review")
        expect(prompt).to include("Comprehensive review")
      end
    end

    it "includes recent activities in prompt" do
      mock_client = instance_double(GeminiClient)
      allow(GeminiClient).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:generate).and_return("Review")

      described_class.new(ai_trainer).call

      expect(mock_client).to have_received(:generate) do |prompt|
        expect(prompt).to include("Activities Since Last Review")
      end
    end
  end
end
