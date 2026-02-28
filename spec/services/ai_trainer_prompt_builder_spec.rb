describe AiTrainerPromptBuilder do
  fixtures :all

  let(:user) { users(:john) }
  let(:ai_trainer) { ai_trainers(:johns_trainer) }

  before do
    ai_trainer.update!(
      approach: :balanced,
      communication_style: :motivational,
      goal_general_fitness: true,
      goal_build_muscle: true,
      train_on_existing_data: false
    )
  end

  describe "#call" do
    it "includes role instructions" do
      result = described_class.new(ai_trainer).call
      expect(result).to include("personalized AI fitness trainer persona")
    end

    it "includes personality section" do
      result = described_class.new(ai_trainer).call
      expect(result).to include("Balanced")
      expect(result).to include("Motivational")
    end

    it "includes goals section" do
      result = described_class.new(ai_trainer).call
      expect(result).to include("Build muscle")
      expect(result).to include("General fitness")
    end

    it "includes custom instructions when present" do
      ai_trainer.update!(custom_instructions: "Focus on compound movements")
      result = described_class.new(ai_trainer).call
      expect(result).to include("Focus on compound movements")
    end

    it "does not include workout data (moved to AiHistoryReviewService)" do
      ai_trainer.update!(train_on_existing_data: true)
      result = described_class.new(ai_trainer).call
      expect(result).not_to include("Workout History")
    end
  end
end
