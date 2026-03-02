describe GenerateFullReviewJob do
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

  let(:mock_client) do
    instance_double(AiClients::Gemini).tap do |client|
      allow(client).to receive(:generate).and_return("Full review content")
      allow(client).to receive(:generate_chat).and_return("Full review content")
    end
  end

  before { allow(AiClient).to receive(:for).and_return(mock_client) }

  describe "#perform" do
    it "creates a full_review activity" do
      expect { described_class.new.perform(ai_trainer:) }.to change(
        AiTrainerActivity.full_review,
        :count
      ).by(1)

      activity = AiTrainerActivity.full_review.last
      expect(activity.content).to eq("Full review content")
      expect(activity.completed?).to be true
      expect(activity.user).to eq(user)
    end

    it "uses AiCompactionService when recent activities exist" do
      allow(mock_client).to receive(:generate_chat).and_return("Compacted")

      described_class.new.perform(ai_trainer:)

      activity = AiTrainerActivity.full_review.order(created_at: :desc).first
      expect(activity.content).to eq("Compacted")
    end

    it "skips when a full_review was created within the last hour" do
      ai_trainer.ai_trainer_activities.create!(
        user:,
        activity_type: :full_review,
        status: :completed,
        content: "Recent review"
      )

      expect { described_class.new.perform(ai_trainer:) }.not_to change(
        AiTrainerActivity.full_review,
        :count
      )
    end

    it "handles errors gracefully" do
      allow(mock_client).to receive(:generate_chat).and_raise(
        StandardError,
        "API error"
      )
      allow(mock_client).to receive(:generate).and_raise(
        StandardError,
        "API error"
      )

      expect { described_class.new.perform(ai_trainer:) }.not_to raise_error

      activity = AiTrainerActivity.full_review.order(created_at: :desc).first
      expect(activity.failed?).to be true
      expect(activity.error_message).to include("API error")
    end
  end
end
