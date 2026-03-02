describe AiConversationBuilder do
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

  describe "#build" do
    it "starts with system turn containing static instructions and trainer profile" do
      messages = described_class.new(ai_trainer).build

      expect(messages.first[:role]).to eq("user")
      expect(messages.first[:text]).to include(
        "personal fitness trainer AI assistant"
      )
      expect(messages.first[:text]).to include("A balanced fitness trainer.")

      expect(messages[1][:role]).to eq("model")
      expect(messages[1][:text]).to include("Understood")
    end

    it "includes latest full review in system turn" do
      messages = described_class.new(ai_trainer).build

      expect(messages.first[:text]).to include("Latest Training Review")
      expect(messages.first[:text]).to include("Comprehensive review")
    end

    it "includes workout review activities as user/model pairs" do
      messages = described_class.new(ai_trainer).build

      workout_user_msg =
        messages.find do |m|
          m[:role] == "user" && m[:text].include?("Strength workout")
        end
      expect(workout_user_msg).to be_present

      workout_model_idx = messages.index(workout_user_msg) + 1
      expect(messages[workout_model_idx][:role]).to eq("model")
      expect(messages[workout_model_idx][:text]).to include(
        "Great strength workout"
      )
    end

    it "includes weekly report activities as user/model pairs" do
      messages = described_class.new(ai_trainer).build

      weekly_user_msg =
        messages.find do |m|
          m[:role] == "user" && m[:text].include?("Weekly overview")
        end
      expect(weekly_user_msg).to be_present
    end

    it "uses condensed workout data (no rep details)" do
      messages = described_class.new(ai_trainer).build

      workout_msgs =
        messages.select do |m|
          m[:role] == "user" && m[:text].include?("Strength workout")
        end
      workout_msgs.each do |msg|
        expect(msg[:text]).not_to include("x 10")
        expect(msg[:text]).to include("Exercises:")
      end
    end

    it "handles deleted workouts gracefully" do
      activity = ai_trainer_activities(:johns_workout_review)
      activity.update_column(:workout_id, nil)

      messages = described_class.new(ai_trainer).build

      workout_msgs =
        messages.select do |m|
          m[:role] == "user" && m[:text].include?("Strength workout")
        end
      expect(workout_msgs).to be_empty
    end

    it "excludes pending activities" do
      messages = described_class.new(ai_trainer).build

      model_msgs = messages.select { |m| m[:role] == "model" }
      model_texts = model_msgs.map { |m| m[:text] }
      expect(model_texts).not_to include(nil)
    end
  end

  describe "#estimated_token_count" do
    it "returns a positive integer" do
      count = described_class.new(ai_trainer).estimated_token_count
      expect(count).to be > 0
    end
  end

  describe "#compaction_needed?" do
    it "returns false when token count is below threshold" do
      expect(described_class.new(ai_trainer).compaction_needed?).to be false
    end

    it "returns true when token count exceeds threshold" do
      stub_const("AiConversationBuilder::TOKEN_THRESHOLD", 1)
      expect(described_class.new(ai_trainer).compaction_needed?).to be true
    end
  end
end
