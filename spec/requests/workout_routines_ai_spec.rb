describe "WorkoutRoutines AI" do
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

  before { sign_in(user) }

  describe "GET /workout_routines/ai_new" do
    context "with configured AI trainer" do
      before { ai_trainer }

      it "returns success" do
        get ai_new_workout_routines_path
        expect(response).to have_http_status(:success)
      end

      it "shows the questionnaire form" do
        get ai_new_workout_routines_path
        expect(response.body).to include("frequency")
        expect(response.body).to include("split_type")
      end
    end

    context "without configured AI trainer" do
      let(:user_without_ai) { users(:jane) }

      before { sign_in(user_without_ai) }

      it "redirects to index" do
        get ai_new_workout_routines_path
        expect(response).to redirect_to(workout_routines_path)
      end
    end
  end

  describe "POST /workout_routines/ai_create" do
    let(:params) do
      {
        frequency: "3",
        split_type: "Push/Pull/Legs",
        experience_level: "Intermediate",
        additional_context: "No injuries"
      }
    end

    context "with configured AI trainer" do
      before { ai_trainer }

      it "creates a workout routine with pending ai_status" do
        expect {
          post ai_create_workout_routines_path, params: params
        }.to change(WorkoutRoutine, :count).by(1)

        routine = WorkoutRoutine.last
        expect(routine.ai_status).to eq("pending")
      end

      it "enqueues AiRoutineSuggestionJob" do
        expect {
          post ai_create_workout_routines_path, params: params
        }.to have_enqueued_job(AiRoutineSuggestionJob)
      end

      it "redirects to the new routine" do
        post ai_create_workout_routines_path, params: params
        expect(response).to redirect_to(WorkoutRoutine.last)
      end
    end

    context "without configured AI trainer" do
      let(:user_without_ai) { users(:jane) }

      before { sign_in(user_without_ai) }

      it "redirects to index" do
        post ai_create_workout_routines_path, params: params
        expect(response).to redirect_to(workout_routines_path)
      end

      it "does not create a routine" do
        expect {
          post ai_create_workout_routines_path, params: params
        }.not_to change(WorkoutRoutine, :count)
      end
    end
  end

  describe "GET /workout_routines/:id/ai_status" do
    context "when generating" do
      it "returns pending status" do
        routine =
          user.workout_routines.create!(name: "Test", ai_status: :pending)
        get ai_status_workout_routine_path(routine)
        expect(response.parsed_body["status"]).to eq("pending")
      end
    end

    context "when completed" do
      it "returns completed status" do
        routine = user.workout_routines.create!(name: "Test", ai_status: nil)
        get ai_status_workout_routine_path(routine)
        expect(response.parsed_body["status"]).to eq("completed")
      end
    end

    context "when failed" do
      it "returns failed status" do
        routine =
          user.workout_routines.create!(name: "Test", ai_status: :failed)
        get ai_status_workout_routine_path(routine)
        expect(response.parsed_body["status"]).to eq("failed")
      end
    end
  end
end
