describe "WorkoutRoutineDays" do
  fixtures :users, :workout_routines, :workout_routine_days

  let(:user) { users(:john) }
  let(:workout_routine) { workout_routines(:push_pull_legs) }
  let(:workout_routine_day) { workout_routine_days(:push_day) }

  before { sign_in(user) }

  describe "GET /workout_routines/:workout_routine_id/workout_routine_days" do
    it "returns success" do
      get workout_routine_workout_routine_days_path(workout_routine),
          as: :turbo_stream
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /workout_routines/:workout_routine_id/workout_routine_days/new" do
    it "returns success" do
      get new_workout_routine_workout_routine_day_path(workout_routine)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /workout_routines/:workout_routine_id/workout_routine_days" do
    context "with valid params" do
      it "creates a new workout routine day" do
        expect {
          post workout_routine_workout_routine_days_path(workout_routine),
               params: {
                 workout_routine_day: {
                   name: "New Day"
                 }
               }
        }.to change(WorkoutRoutineDay, :count).by(1)
      end

      it "redirects to edit page" do
        post workout_routine_workout_routine_days_path(workout_routine),
             params: {
               workout_routine_day: {
                 name: "New Day"
               }
             }
        expect(response).to redirect_to(
          edit_workout_routine_workout_routine_day_path(
            workout_routine,
            WorkoutRoutineDay.last
          )
        )
      end
    end

    context "with invalid params" do
      it "renders new form" do
        post workout_routine_workout_routine_days_path(workout_routine),
             params: {
               workout_routine_day: {
                 name: ""
               }
             }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "GET /workout_routines/:workout_routine_id/workout_routine_days/:id/edit" do
    it "returns success" do
      get edit_workout_routine_workout_routine_day_path(
            workout_routine,
            workout_routine_day
          )
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /workout_routines/:workout_routine_id/workout_routine_days/:id" do
    context "with valid params" do
      it "updates the workout routine day" do
        patch workout_routine_workout_routine_day_path(
                workout_routine,
                workout_routine_day
              ),
              params: {
                workout_routine_day: {
                  name: "Updated Day"
                }
              }
        expect(workout_routine_day.reload.name).to eq("Updated Day")
      end

      it "redirects to workout routine" do
        patch workout_routine_workout_routine_day_path(
                workout_routine,
                workout_routine_day
              ),
              params: {
                workout_routine_day: {
                  name: "Updated Day"
                }
              }
        expect(response).to redirect_to(workout_routine_path(workout_routine))
      end
    end

    context "with invalid params" do
      it "renders edit form" do
        patch workout_routine_workout_routine_day_path(
                workout_routine,
                workout_routine_day
              ),
              params: {
                workout_routine_day: {
                  name: ""
                }
              }
        expect(response).to have_http_status(:success)
      end
    end
  end
end
