describe AiPromptContextBuilder do
  fixtures :all

  let(:user) { users(:john) }
  let(:ai_trainer) do
    ai_trainers(:johns_trainer).tap do |t|
      t.update!(
        status: :completed,
        trainer_profile: "A motivational balanced fitness trainer."
      )
    end
  end

  describe "#call" do
    it "includes static instructions" do
      result = described_class.new(ai_trainer).call
      expect(result).to include("personal fitness trainer AI assistant")
    end

    it "includes trainer profile" do
      result = described_class.new(ai_trainer).call
      expect(result).to include("A motivational balanced fitness trainer.")
    end

    it "excludes trainer profile when blank" do
      ai_trainer.update!(trainer_profile: nil)
      result = described_class.new(ai_trainer).call
      expect(result).not_to include("Your Trainer Profile")
    end

    it "includes latest full review content" do
      result = described_class.new(ai_trainer).call
      expect(result).to include("Latest Training Review")
      expect(result).to include("Comprehensive review")
    end

    it "includes recent activities since last review" do
      result = described_class.new(ai_trainer).call
      expect(result).to include("Recent Activity Context")
    end
  end
end
