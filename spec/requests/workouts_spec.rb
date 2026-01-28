require "rails_helper"

describe "Workouts" do
  fixtures :users,
           :exercises,
           :workout_routines,
           :workout_routine_days,
           :workout_routine_day_exercises

  let(:user) { users(:john) }

  before { sign_in(user) }

  describe "GET /workouts" do
    it "returns success" do
      get workouts_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /workouts/new" do
    it "returns success" do
      get new_workout_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /workouts" do
    context "with a workout routine day (standard routine)" do
      it "creates a strength workout" do
        expect {
          post workouts_path,
               params: {
                 workout: {
                   workout_type: "strength",
                   workout_routine_day_id: workout_routine_days(:push_day).id
                 }
               }
        }.to change(Workout, :count).by(1)

        workout = Workout.last
        expect(workout.strength?).to be true
        expect(workout.workout_routine_day).to eq(
          workout_routine_days(:push_day)
        )
        expect(workout.user).to eq(user)
        expect(response).to redirect_to(workout_path(workout))
      end
    end

    context "without a workout routine day (custom routine)" do
      it "creates a strength workout without a routine" do
        expect {
          post workouts_path,
               params: {
                 workout: {
                   workout_type: "strength",
                   workout_routine_day_id: nil
                 }
               }
        }.to change(Workout, :count).by(1)

        workout = Workout.last
        expect(workout.strength?).to be true
        expect(workout.workout_routine_day).to be_nil
        expect(workout.user).to eq(user)
        expect(response).to redirect_to(workout_path(workout))
      end
    end

    context "with run workout type" do
      it "creates a run workout" do
        expect {
          post workouts_path,
               params: {
                 workout: {
                   workout_type: "run",
                   started_at: Date.today,
                   distance: 5000,
                   time_in_seconds: "30:00"
                 }
               }
        }.to change(Workout, :count).by(1)

        workout = Workout.last
        expect(workout.run?).to be true
        expect(workout.distance).to eq(5000)
        expect(workout.time_in_seconds).to eq(1800)
        expect(response).to redirect_to(workouts_path)
      end
    end

    context "when user already has an active workout" do
      before do
        Workout.create!(
          user: user,
          workout_type: :strength,
          started_at: 1.hour.ago,
          workout_routine_day: workout_routine_days(:push_day)
        )
      end

      it "does not create a new workout" do
        expect {
          post workouts_path,
               params: {
                 workout: {
                   workout_type: "strength",
                   workout_routine_day_id: workout_routine_days(:pull_day).id
                 }
               }
        }.not_to change(Workout, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("You already have an active workout")
      end
    end
  end

  describe "POST /workouts/:id/stop" do
    let!(:workout) do
      Workout.create!(
        user: user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        workout_routine_day: workout_routine_days(:push_day)
      )
    end

    it "ends the workout" do
      expect(workout.ended_at).to be_nil

      post stop_workout_path(workout)

      workout.reload
      expect(workout.ended_at).to be_present
      expect(response).to redirect_to(workouts_path)
    end

    it "ends all active workout sets" do
      workout_set =
        workout.workout_sets.create!(
          exercise: exercises(:bench_press),
          started_at: 30.minutes.ago
        )

      post stop_workout_path(workout)

      workout_set.reload
      expect(workout_set.ended_at).to be_present
    end
  end

  describe "POST /workouts/:id/pause" do
    let!(:workout) do
      Workout.create!(
        user: user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        workout_routine_day: workout_routine_days(:push_day)
      )
    end

    it "pauses the workout" do
      expect(workout.paused_at).to be_nil

      post pause_workout_path(workout)

      workout.reload
      expect(workout.paused_at).to be_present
      expect(response).to redirect_to(workout_path(workout))
    end
  end

  describe "POST /workouts/:id/resume" do
    let!(:workout) do
      Workout.create!(
        user: user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        paused_at: 10.minutes.ago,
        workout_routine_day: workout_routine_days(:push_day)
      )
    end

    it "resumes the workout" do
      post resume_workout_path(workout)

      workout.reload
      expect(workout.paused_at).to be_nil
      expect(workout.total_paused_seconds).to be > 0
      expect(response).to redirect_to(workout_path(workout))
    end
  end

  describe "DELETE /workouts/:id" do
    let!(:workout) do
      Workout.create!(
        user: user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        ended_at: Time.current,
        workout_routine_day: workout_routine_days(:push_day)
      )
    end

    it "deletes the workout" do
      expect { delete workout_path(workout) }.to change(Workout, :count).by(-1)

      expect(response).to redirect_to(workouts_path)
    end
  end

  describe "GET /workouts/:id with bodyweight exercises" do
    let!(:workout) do
      Workout.create!(
        user: user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        workout_routine_day: workout_routine_days(:push_day)
      )
    end

    it "renders workout with exercise without weights or band (e.g. pull-up)" do
      workout.workout_sets.create!(
        exercise: exercises(:pull_up),
        started_at: 30.minutes.ago
      )

      get workout_path(workout)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Pull-Up")
    end

    it "renders workout with exercise with band but no weights" do
      workout.workout_sets.create!(
        exercise: exercises(:banded_squat),
        started_at: 30.minutes.ago
      )

      get workout_path(workout)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Banded Squat")
    end
  end
end
