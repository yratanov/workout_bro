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
        {
          name: "Push Day",
          exercises: [
            { name: "Bench Press", muscle: "chest" },
            { name: "Tricep Extension", muscle: "triceps" }
          ]
        },
        {
          name: "Pull Day",
          exercises: [
            { name: "Deadlift", muscle: "back" },
            { name: "Pull-Up", muscle: "back" },
            { name: "Bicep Curl", muscle: "biceps" }
          ]
        },
        { name: "Leg Day", exercises: [{ name: "Squat", muscle: "legs" }] }
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

    it "saves comments on exercises from AI response" do
      response = {
        name: "Commented Routine",
        days: [
          {
            name: "Day 1",
            exercises: [
              {
                name: "Bench Press",
                muscle: "chest",
                comment: "focus on form"
              },
              { name: "Squat", muscle: "legs" }
            ]
          }
        ]
      }.to_json

      allow(mock_client).to receive(:generate_chat).and_return(response)

      described_class.new.perform(
        workout_routine: workout_routine,
        params: params
      )

      day = workout_routine.reload.workout_routine_days.first
      exercises = day.workout_routine_day_exercises.order(:position)
      expect(exercises.first.comment).to eq("focus on form")
      expect(exercises.second.comment).to be_nil
    end

    it "saves comments on superset exercises from AI response" do
      response = {
        name: "Superset Comment Routine",
        days: [
          {
            name: "Day 1",
            exercises: [
              {
                superset: "Chest/Back Superset",
                comment: "no rest between exercises",
                exercises: [
                  { name: "Bench Press", muscle: "chest" },
                  { name: "Deadlift", muscle: "back" }
                ]
              }
            ]
          }
        ]
      }.to_json

      allow(mock_client).to receive(:generate_chat).and_return(response)

      described_class.new.perform(
        workout_routine: workout_routine,
        params: params
      )

      day = workout_routine.reload.workout_routine_days.first
      day_exercise = day.workout_routine_day_exercises.first
      expect(day_exercise.comment).to eq("no rest between exercises")
    end

    it "creates new exercises when not found in user's list" do
      response = {
        name: "Test Routine",
        days: [
          {
            name: "Day 1",
            exercises: [{ name: "Overhead Press", muscle: "shoulders" }]
          }
        ]
      }.to_json

      allow(mock_client).to receive(:generate_chat).and_return(response)

      expect {
        described_class.new.perform(
          workout_routine: workout_routine,
          params: params
        )
      }.to change(Exercise, :count).by(1)

      new_exercise = user.exercises.find_by(name: "Overhead Press")
      expect(new_exercise).to be_present
      expect(new_exercise.muscle.name).to eq("shoulders")
      expect(new_exercise.with_weights).to be(true)

      day = workout_routine.reload.workout_routine_days.first
      expect(day.workout_routine_day_exercises.count).to eq(1)
      expect(day.workout_routine_day_exercises.first.exercise).to eq(
        new_exercise
      )
    end

    it "skips exercises with invalid muscle group" do
      response = {
        name: "Test Routine",
        days: [
          {
            name: "Day 1",
            exercises: [
              { name: "Bench Press", muscle: "chest" },
              { name: "Magic Lift", muscle: "nonexistent_muscle" }
            ]
          }
        ]
      }.to_json

      allow(mock_client).to receive(:generate_chat).and_return(response)

      described_class.new.perform(
        workout_routine: workout_routine,
        params: params
      )

      day = workout_routine.reload.workout_routine_days.first
      expect(day.workout_routine_day_exercises.count).to eq(1)
      expect(day.workout_routine_day_exercises.first.exercise.name).to eq(
        "Bench Press"
      )
    end

    it "creates supersets with component exercises" do
      response = {
        name: "Superset Routine",
        days: [
          {
            name: "Day 1",
            exercises: [
              {
                superset: "Chest/Back Superset",
                exercises: [
                  { name: "Bench Press", muscle: "chest" },
                  { name: "Deadlift", muscle: "back" }
                ]
              }
            ]
          }
        ]
      }.to_json

      allow(mock_client).to receive(:generate_chat).and_return(response)

      expect {
        described_class.new.perform(
          workout_routine: workout_routine,
          params: params
        )
      }.to change(Superset, :count).by(1)

      superset = user.supersets.find_by(name: "Chest/Back Superset")
      expect(superset).to be_present
      expect(superset.exercises.map(&:name)).to contain_exactly(
        "Bench Press",
        "Deadlift"
      )

      day = workout_routine.reload.workout_routine_days.first
      day_exercise = day.workout_routine_day_exercises.first
      expect(day_exercise.superset).to eq(superset)
      expect(day_exercise.exercise).to be_nil
    end

    it "reuses existing supersets by name" do
      existing_superset = supersets(:push_pull)

      response = {
        name: "Reuse Routine",
        days: [
          {
            name: "Day 1",
            exercises: [
              {
                superset: "Push Pull",
                exercises: [
                  { name: "Bench Press", muscle: "chest" },
                  { name: "Pull-Up", muscle: "back" }
                ]
              }
            ]
          }
        ]
      }.to_json

      allow(mock_client).to receive(:generate_chat).and_return(response)

      expect {
        described_class.new.perform(
          workout_routine: workout_routine,
          params: params
        )
      }.not_to change(Superset, :count)

      day = workout_routine.reload.workout_routine_days.first
      expect(day.workout_routine_day_exercises.first.superset).to eq(
        existing_superset
      )
    end

    it "creates supersets with new exercises" do
      response = {
        name: "New Superset Routine",
        days: [
          {
            name: "Day 1",
            exercises: [
              {
                superset: "Shoulder Combo",
                exercises: [
                  { name: "Lateral Raise", muscle: "shoulders" },
                  { name: "Front Raise", muscle: "shoulders" }
                ]
              }
            ]
          }
        ]
      }.to_json

      allow(mock_client).to receive(:generate_chat).and_return(response)

      expect {
        described_class.new.perform(
          workout_routine: workout_routine,
          params: params
        )
      }.to change(Exercise, :count).by(2).and change(Superset, :count).by(1)

      superset = user.supersets.find_by(name: "Shoulder Combo")
      expect(superset.exercises.map(&:name)).to contain_exactly(
        "Lateral Raise",
        "Front Raise"
      )
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
