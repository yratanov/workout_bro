describe AiWorkoutFeedbackService do
  fixtures :users, :exercises, :muscles, :workout_routine_days, :ai_trainers

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
        trainer_profile: "A motivational trainer profile."
      )
    end
  end

  let(:workout) do
    Workout.create!(
      user: user,
      workout_type: :strength,
      started_at: 1.hour.ago,
      ended_at: Time.current,
      workout_routine_day: workout_routine_days(:push_day)
    )
  end

  before { ai_trainer }

  describe "#call" do
    it "calls generate_chat with conversation messages when trainer is configured" do
      workout_set =
        workout.workout_sets.create!(
          exercise: exercises(:bench_press),
          started_at: 30.minutes.ago
        )
      workout_set.workout_reps.create!(weight: 100, reps: 10)

      mock_client = instance_double(GeminiClient)
      allow(GeminiClient).to receive(:new).with(
        api_key: "test-key",
        model: "gemini-2.0-flash"
      ).and_return(mock_client)
      allow(mock_client).to receive(:generate_chat).and_return("Great workout!")

      result = described_class.new(workout).call

      expect(result).to eq("Great workout!")
      expect(mock_client).to have_received(:generate_chat) do |messages, **|
        expect(messages).to be_an(Array)
        last_msg = messages.last
        expect(last_msg[:role]).to eq("user")
        expect(last_msg[:text]).to include("Strength")
        expect(last_msg[:text]).to include("Bench Press")
        expect(last_msg[:text]).to include("100")
      end
    end

    it "includes trainer context in conversation messages" do
      mock_client = instance_double(GeminiClient)
      allow(GeminiClient).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:generate_chat).and_return("Feedback")

      described_class.new(workout).call

      expect(mock_client).to have_received(:generate_chat) do |messages, **|
        system_msg = messages.first
        expect(system_msg[:text]).to include("A motivational trainer profile.")
      end
    end

    it "falls back to generate for unconfigured trainer" do
      ai_trainer.update!(status: :pending)

      mock_client = instance_double(GeminiClient)
      allow(GeminiClient).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:generate).and_return("Basic feedback")

      result = described_class.new(workout).call

      expect(result).to eq("Basic feedback")
      expect(mock_client).to have_received(:generate)
    end

    context "with a run workout" do
      let(:run_workout) do
        Workout.create!(
          user: user,
          workout_type: :run,
          started_at: 1.hour.ago,
          ended_at: Time.current,
          distance: 5000,
          time_in_seconds: 1800
        )
      end

      it "includes run details in the last message" do
        mock_client = instance_double(GeminiClient)
        allow(GeminiClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:generate_chat).and_return("Nice run!")

        result = described_class.new(run_workout).call

        expect(result).to eq("Nice run!")
        expect(mock_client).to have_received(:generate_chat) do |messages, **|
          last_msg = messages.last
          expect(last_msg[:text]).to include("Run")
          expect(last_msg[:text]).to include("5.0km")
        end
      end
    end
  end
end
