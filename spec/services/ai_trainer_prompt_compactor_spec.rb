describe AiTrainerPromptCompactor do
  fixtures :users, :ai_trainers

  let(:user) do
    users(:john).tap do |u|
      u.update!(
        ai_provider: "gemini",
        ai_model: "gemini-2.0-flash",
        ai_api_key: "test-key"
      )
    end
  end

  let(:base_prompt) do
    "You are a personal fitness trainer AI assistant.\n\n## Your Trainer Profile\nA motivational trainer."
  end

  let(:ai_trainer) do
    user.ai_trainer.tap do |t|
      t.update!(
        status: :completed,
        summary: "A motivational trainer.",
        system_prompt: base_prompt
      )
    end
  end

  let(:compactor) { described_class.new(ai_trainer) }

  describe "#should_compact?" do
    it "returns false when there are fewer than 4 weekly sections" do
      ai_trainer.update!(
        system_prompt: "#{base_prompt}\n\n## Week 1\nNotes\n\n## Week 2\nNotes"
      )
      expect(compactor.should_compact?).to be false
    end

    it "returns true when there are 4 or more weekly sections" do
      weeks =
        (1..4).map { |i| "## Week #{i}\nNotes for week #{i}" }.join("\n\n")
      ai_trainer.update!(system_prompt: "#{base_prompt}\n\n#{weeks}")
      expect(compactor.should_compact?).to be true
    end

    it "returns false when system_prompt is nil" do
      ai_trainer.update!(system_prompt: nil)
      expect(compactor.should_compact?).to be false
    end
  end

  describe "#weekly_section_count" do
    it "counts the number of ## Week sections" do
      weeks = (1..3).map { |i| "## Week #{i}\nNotes" }.join("\n\n")
      ai_trainer.update!(system_prompt: "#{base_prompt}\n\n#{weeks}")
      expect(compactor.weekly_section_count).to eq(3)
    end
  end

  describe "#call" do
    it "does not compact when below threshold" do
      ai_trainer.update!(system_prompt: "#{base_prompt}\n\n## Week 1\nNotes")
      expect(GeminiClient).not_to receive(:new)
      compactor.call
    end

    it "compacts the prompt when threshold is reached" do
      weeks =
        (1..4).map { |i| "## Week #{i}\nNotes for week #{i}" }.join("\n\n")
      ai_trainer.update!(system_prompt: "#{base_prompt}\n\n#{weeks}")

      compacted_prompt =
        "#{base_prompt}\n\n## Accumulated Insights\nConsolidated notes."

      mock_client = instance_double(GeminiClient)
      allow(GeminiClient).to receive(:new).with(
        api_key: "test-key",
        model: "gemini-2.0-flash"
      ).and_return(mock_client)
      allow(mock_client).to receive(:generate).and_return(compacted_prompt)

      compactor.call

      expect(ai_trainer.reload.system_prompt).to eq(compacted_prompt)
      expect(mock_client).to have_received(:generate) do |prompt, **_opts|
        expect(prompt).to include("## Week 1")
        expect(prompt).to include("## Week 4")
        expect(prompt).to include("Consolidate all")
      end
    end

    it "logs the AI request with compact_trainer_prompt action" do
      weeks = (1..4).map { |i| "## Week #{i}\nNotes" }.join("\n\n")
      ai_trainer.update!(system_prompt: "#{base_prompt}\n\n#{weeks}")

      mock_client = instance_double(GeminiClient)
      allow(GeminiClient).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:generate).and_return("Compacted prompt")

      compactor.call

      expect(mock_client).to have_received(:generate).with(
        anything,
        log_context: {
          user: user,
          action: "compact_trainer_prompt"
        }
      )
    end
  end
end
