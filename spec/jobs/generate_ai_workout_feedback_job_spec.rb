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

  let(:mock_conversation) do
    { system_instruction: "You are a trainer.", messages: [] }
  end

  before { ai_trainer }

  describe "#perform" do
    it "creates a completed activity" do
      mock_service =
        instance_double(AiWorkoutFeedbackService, call: "Great workout!")
      allow(AiWorkoutFeedbackService).to receive(:new).and_return(mock_service)
      allow(mock_service).to receive(:send).with(:request_message).and_return(
        "Workout data"
      )

      mock_builder =
        instance_double(
          AiConversationBuilder,
          build: mock_conversation,
          compaction_needed?: false
        )
      allow(AiConversationBuilder).to receive(:new).and_return(mock_builder)

      mock_client = instance_double(AiClients::Gemini)
      allow(AiClient).to receive(:for).and_return(mock_client)
      allow(mock_client).to receive(:generate_chat_stream).and_return(
        "Great workout!"
      )

      described_class.new.perform(workout:)

      activity = workout.reload.ai_trainer_activity
      expect(activity).to be_completed
      expect(activity.content).to eq("Great workout!")
    end

    it "triggers compaction when conversation exceeds token threshold" do
      mock_service = instance_double(AiWorkoutFeedbackService, call: "Feedback")
      allow(AiWorkoutFeedbackService).to receive(:new).and_return(mock_service)
      allow(mock_service).to receive(:send).with(:request_message).and_return(
        "Workout data"
      )

      mock_builder =
        instance_double(
          AiConversationBuilder,
          build: mock_conversation,
          compaction_needed?: true
        )
      allow(AiConversationBuilder).to receive(:new).and_return(mock_builder)

      mock_client = instance_double(AiClients::Gemini)
      allow(AiClient).to receive(:for).and_return(mock_client)
      allow(mock_client).to receive(:generate_chat_stream).and_return(
        "Feedback"
      )

      expect { described_class.new.perform(workout:) }.to have_enqueued_job(
        GenerateFullReviewJob
      )
    end

    it "does not trigger compaction when under threshold" do
      mock_service = instance_double(AiWorkoutFeedbackService, call: "Feedback")
      allow(AiWorkoutFeedbackService).to receive(:new).and_return(mock_service)
      allow(mock_service).to receive(:send).with(:request_message).and_return(
        "Workout data"
      )

      mock_builder =
        instance_double(
          AiConversationBuilder,
          build: mock_conversation,
          compaction_needed?: false
        )
      allow(AiConversationBuilder).to receive(:new).and_return(mock_builder)

      mock_client = instance_double(AiClients::Gemini)
      allow(AiClient).to receive(:for).and_return(mock_client)
      allow(mock_client).to receive(:generate_chat_stream).and_return(
        "Feedback"
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
