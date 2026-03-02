describe AiRoutineSuggestionJob do
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

  let(:workout_routine) do
    user.workout_routines.create!(
      name: "AI Routine (generating...)",
      ai_status: :pending
    )
  end

  let(:params) do
    {
      frequency: "3",
      split_type: "Push/Pull/Legs",
      experience_level: "Intermediate",
      focus_areas: [],
      additional_context: ""
    }
  end

  let(:ai_response) do
    {
      name: "Push Pull Legs Routine",
      days: [
        { name: "Push Day", exercises: ["Bench Press", "Tricep Extension"] },
        { name: "Pull Day", exercises: ["Deadlift", "Pull-Up", "Bicep Curl"] },
        { name: "Leg Day", exercises: ["Squat"] }
      ]
    }.to_json
  end

  let(:mock_client) { instance_double(AiClients::Gemini) }

  before do
    ai_trainer
    allow(AiClient).to receive(:for).and_return(mock_client)
  end

  describe "#perform" do
    it "creates routine days and exercises from AI response" do
      allow(mock_client).to receive(:generate_chat).and_return(ai_response)

      described_class.new.perform(
        workout_routine: workout_routine,
        params: params
      )

      workout_routine.reload
      expect(workout_routine.ai_status).to be_nil
      expect(workout_routine.name).to eq("Push Pull Legs Routine")
      expect(workout_routine.workout_routine_days.count).to eq(3)

      push_day = workout_routine.workout_routine_days.find_by(name: "Push Day")
      expect(push_day.workout_routine_day_exercises.count).to eq(2)
    end

    it "sets ai_status to in_progress during execution" do
      allow(mock_client).to receive(:generate_chat) do
        expect(workout_routine.reload.ai_status).to eq("in_progress")
        ai_response
      end

      described_class.new.perform(
        workout_routine: workout_routine,
        params: params
      )
    end

    it "skips unmatched exercise names" do
      response_with_unknown = {
        name: "Test Routine",
        days: [
          { name: "Day 1", exercises: ["Bench Press", "Unknown Exercise"] }
        ]
      }.to_json

      allow(mock_client).to receive(:generate_chat).and_return(
        response_with_unknown
      )

      described_class.new.perform(
        workout_routine: workout_routine,
        params: params
      )

      day = workout_routine.reload.workout_routine_days.first
      expect(day.workout_routine_day_exercises.count).to eq(1)
    end

    it "sets failed status on error" do
      allow(mock_client).to receive(:generate_chat).and_raise(
        StandardError.new("API error")
      )

      expect {
        described_class.new.perform(
          workout_routine: workout_routine,
          params: params
        )
      }.to raise_error(StandardError)

      workout_routine.reload
      expect(workout_routine.ai_status).to eq("failed")
      expect(workout_routine.ai_generation_error).to eq("API error")
    end

    it "uses simple generate when trainer not configured" do
      ai_trainer.update!(status: :pending, trainer_profile: nil)
      allow(mock_client).to receive(:generate).and_return(ai_response)

      described_class.new.perform(
        workout_routine: workout_routine,
        params: params
      )

      expect(mock_client).to have_received(:generate)
      expect(workout_routine.reload.ai_status).to be_nil
    end
  end
end
