describe GenerateAiWorkoutFeedbackJob do
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

  let(:workout) do
    Workout.create!(
      user: user,
      workout_type: :strength,
      started_at: 1.hour.ago,
      ended_at: Time.current
    )
  end

  before { ai_trainer }

  describe "#perform" do
    it "creates a completed activity and writes ai_summary" do
      mock_service =
        instance_double(AiWorkoutFeedbackService, call: "Great workout!")
      allow(AiWorkoutFeedbackService).to receive(:new).and_return(mock_service)
      allow(AiConversationBuilder).to receive(:new).and_return(
        instance_double(AiConversationBuilder, compaction_needed?: false)
      )

      described_class.new.perform(workout:)

      activity = workout.reload.ai_trainer_activity
      expect(activity).to be_completed
      expect(activity.content).to eq("Great workout!")
      expect(workout.ai_summary).to eq("Great workout!")
    end

    it "triggers compaction when conversation exceeds token threshold" do
      mock_service = instance_double(AiWorkoutFeedbackService, call: "Feedback")
      allow(AiWorkoutFeedbackService).to receive(:new).and_return(mock_service)
      allow(AiConversationBuilder).to receive(:new).and_return(
        instance_double(AiConversationBuilder, compaction_needed?: true)
      )

      expect { described_class.new.perform(workout:) }.to have_enqueued_job(
        GenerateFullReviewJob
      )
    end

    it "does not trigger compaction when under threshold" do
      mock_service = instance_double(AiWorkoutFeedbackService, call: "Feedback")
      allow(AiWorkoutFeedbackService).to receive(:new).and_return(mock_service)
      allow(AiConversationBuilder).to receive(:new).and_return(
        instance_double(AiConversationBuilder, compaction_needed?: false)
      )

      expect { described_class.new.perform(workout:) }.not_to have_enqueued_job(
        GenerateFullReviewJob
      )
    end

    it "skips if activity is already completed" do
      AiTrainerActivity.create!(
        user:,
        ai_trainer:,
        workout:,
        activity_type: :workout_review,
        status: :completed,
        content: "Already done"
      )

      expect(AiWorkoutFeedbackService).not_to receive(:new)

      described_class.new.perform(workout:)
    end
  end
end
