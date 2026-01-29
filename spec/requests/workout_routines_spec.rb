describe "WorkoutRoutines" do
  fixtures :users, :workout_routines, :workout_routine_days, :exercises

  let(:user) { users(:john) }
  let(:workout_routine) { workout_routines(:push_pull_legs) }

  before { sign_in(user) }

  describe "GET /workout_routines" do
    it "returns success" do
      get workout_routines_path
      expect(response).to have_http_status(:success)
    end

    it "shows user's workout routines" do
      get workout_routines_path
      expect(response.body).to include(workout_routine.name)
    end
  end

  describe "GET /workout_routines/:id" do
    it "returns success" do
      get workout_routine_path(workout_routine)
      expect(response).to have_http_status(:success)
    end

    it "shows workout routine details" do
      get workout_routine_path(workout_routine)
      expect(response.body).to include(workout_routine.name)
    end
  end

  describe "GET /workout_routines/new" do
    it "returns success" do
      get new_workout_routine_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /workout_routines" do
    context "with valid params" do
      it "creates a new workout routine" do
        expect {
          post workout_routines_path,
               params: {
                 workout_routine: {
                   name: "New Routine"
                 }
               }
        }.to change(WorkoutRoutine, :count).by(1)
      end

      it "redirects to the new routine" do
        post workout_routines_path,
             params: {
               workout_routine: {
                 name: "New Routine"
               }
             }
        expect(response).to redirect_to(WorkoutRoutine.last)
      end
    end

    context "with invalid params" do
      before do
        allow_any_instance_of(WorkoutRoutine).to receive(:save).and_return(
          false
        )
      end

      it "returns unprocessable entity" do
        post workout_routines_path,
             params: {
               workout_routine: {
                 name: "Test"
               }
             }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /workout_routines/:id" do
    let(:deletable_routine) do
      user.workout_routines.create!(name: "Deletable Routine")
    end

    it "destroys the workout routine" do
      deletable_routine
      expect { delete workout_routine_path(deletable_routine) }.to change(
        WorkoutRoutine,
        :count
      ).by(-1)
    end

    it "redirects to index" do
      delete workout_routine_path(deletable_routine)
      expect(response).to redirect_to(workout_routines_path)
    end
  end
end
