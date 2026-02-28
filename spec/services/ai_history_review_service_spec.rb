describe AiHistoryReviewService do
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
        trainer_profile: "A motivational fitness trainer."
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
      allow(mock_client).to receive(:generate).and_return(
        "Training review content"
      )

      result = described_class.new(ai_trainer).call

      expect(result).to eq("Training review content")
      expect(mock_client).to have_received(:generate) do |prompt|
        expect(prompt).to include("Trainer Profile")
        expect(prompt).to include("comprehensive training review")
      end
    end

    it "includes workout data when available" do
      workout =
        user.workouts.create!(
          workout_type: :strength,
          started_at: 1.day.ago,
          ended_at: Time.current,
          date: Date.current
        )

      exercise =
        user.exercises.first || user.exercises.create!(name: "Bench Press")
      ws =
        workout.workout_sets.create!(
          exercise:,
          started_at: 1.day.ago,
          ended_at: Time.current
        )
      ws.workout_reps.create!(reps: 10, weight: 60)

      mock_client = instance_double(GeminiClient)
      allow(GeminiClient).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:generate).and_return("Review")

      described_class.new(ai_trainer).call

      expect(mock_client).to have_received(:generate) do |prompt|
        expect(prompt).to include("Workout History")
      end
    end
  end
end
