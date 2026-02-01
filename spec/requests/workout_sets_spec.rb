describe "WorkoutSets" do
  fixtures :users, :exercises, :workout_routines, :workout_routine_days

  let(:user) { users(:john) }
  let(:workout) do
    Workout.create!(
      user: user,
      workout_type: :strength,
      started_at: 1.hour.ago,
      workout_routine_day: workout_routine_days(:push_day)
    )
  end
  let(:workout_set) do
    workout.workout_sets.create!(
      exercise: exercises(:bench_press),
      started_at: 30.minutes.ago
    )
  end

  before { sign_in(user) }

  describe "GET /workout_sets/:id/notes_modal" do
    it "returns the notes modal" do
      get notes_modal_workout_set_path(workout_set)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Notes for")
      expect(response.body).to include("Bench Press")
    end
  end

  describe "PATCH /workout_sets/:id/update_notes" do
    it "updates the workout set notes" do
      patch update_notes_workout_set_path(workout_set),
            params: {
              workout_set: {
                notes: "Good form on this set"
              }
            }

      workout_set.reload
      expect(workout_set.notes).to eq("Good form on this set")
    end

    it "returns turbo stream response" do
      patch update_notes_workout_set_path(workout_set),
            params: {
              workout_set: {
                notes: "Test notes"
              }
            },
            headers: {
              "Accept" => "text/vnd.turbo-stream.html"
            }

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end
  end
end
