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

    it "ends the workout and redirects to summary" do
      expect(workout.ended_at).to be_nil

      post stop_workout_path(workout)

      workout.reload
      expect(workout.ended_at).to be_present
      expect(response).to redirect_to(summary_workout_path(workout))
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

    context "with PR detection" do
      before { user.personal_records.destroy_all }

      it "creates personal records when workout ends" do
        workout_set =
          workout.workout_sets.create!(
            exercise: exercises(:bench_press),
            started_at: 30.minutes.ago
          )
        workout_set.workout_reps.create!(weight: 100, reps: 10)

        expect { post stop_workout_path(workout) }.to change(
          PersonalRecord,
          :count
        ).by(2)
      end

      it "stores PR IDs in session for summary page" do
        workout_set =
          workout.workout_sets.create!(
            exercise: exercises(:bench_press),
            started_at: 30.minutes.ago
          )
        workout_set.workout_reps.create!(weight: 100, reps: 10)

        post stop_workout_path(workout)

        expect(session[:workout_summary_prs]).to be_present
        expect(session[:workout_summary_prs].size).to eq(2)
      end
    end
  end

  describe "GET /workouts/:id/summary" do
    fixtures :muscles

    let!(:workout) do
      Workout.create!(
        user: user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        ended_at: Time.current,
        workout_routine_day: workout_routine_days(:push_day)
      )
    end

    it "returns success for completed workout" do
      get summary_workout_path(workout)
      expect(response).to have_http_status(:success)
    end

    it "redirects to workouts_path for incomplete workout" do
      workout.update!(ended_at: nil)
      get summary_workout_path(workout)
      expect(response).to redirect_to(workouts_path)
    end

    it "returns 404 for another user's workout" do
      other_workout =
        Workout.create!(
          user: users(:jane),
          workout_type: :strength,
          started_at: 1.hour.ago,
          ended_at: Time.current
        )
      get summary_workout_path(other_workout)
      expect(response).to have_http_status(:not_found)
    end

    it "displays total volume" do
      workout_set =
        workout.workout_sets.create!(
          exercise: exercises(:bench_press),
          started_at: 30.minutes.ago
        )
      workout_set.workout_reps.create!(weight: 100, reps: 10)

      get summary_workout_path(workout)

      # The total volume of 1000 (100kg x 10 reps) should appear in the page
      # Check for the formatted volume in the stats grid
      expect(response.body).to include("Total Volume")
      expect(response.body).to match(/1000|1t/)
    end

    it "displays muscles worked" do
      workout.workout_sets.create!(
        exercise: exercises(:bench_press),
        started_at: 30.minutes.ago
      )

      get summary_workout_path(workout)

      expect(response.body).to include("Chest")
    end

    it "displays workout complete title" do
      get summary_workout_path(workout)

      expect(response.body).to include("Workout Complete!")
    end

    it "displays routine information" do
      get summary_workout_path(workout)

      expect(response.body).to include("Push Day")
      expect(response.body).to include("Push Pull Legs")
    end
  end

  describe "POST /workouts/:id/stop with AI trainer" do
    fixtures :ai_trainers

    let!(:workout) do
      Workout.create!(
        user: user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        workout_routine_day: workout_routine_days(:push_day)
      )
    end

    context "when user has a configured AI trainer" do
      before do
        user.update!(
          ai_provider: "gemini",
          ai_model: "gemini-2.0-flash",
          ai_api_key: "test-key"
        )
        user.ai_trainer.update!(
          status: :completed,
          trainer_profile: "Trainer profile."
        )
      end

      it "enqueues GenerateAiWorkoutFeedbackJob" do
        expect { post stop_workout_path(workout) }.to have_enqueued_job(
          GenerateAiWorkoutFeedbackJob
        )
      end
    end

    context "when user has no AI trainer" do
      before { user.ai_trainer&.destroy }

      it "does not enqueue GenerateAiWorkoutFeedbackJob" do
        expect { post stop_workout_path(workout) }.not_to have_enqueued_job(
          GenerateAiWorkoutFeedbackJob
        )
      end
    end
  end

  describe "GET /workouts/:id/ai_feedback_status" do
    let!(:workout) do
      Workout.create!(
        user: user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        ended_at: Time.current,
        workout_routine_day: workout_routine_days(:push_day)
      )
    end

    it "returns pending when no activity" do
      get ai_feedback_status_workout_path(workout), as: :json

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["status"]).to eq("pending")
      expect(json["ai_summary"]).to be_nil
    end

    it "returns completed with content when activity is completed" do
      ai_trainer =
        user.ai_trainer ||
          user.create_ai_trainer!(
            status: :completed,
            trainer_profile: "Profile"
          )
      AiTrainerActivity.create!(
        user: user,
        ai_trainer: ai_trainer,
        workout: workout,
        activity_type: :workout_review,
        content: "Great workout!",
        status: :completed
      )

      get ai_feedback_status_workout_path(workout), as: :json

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["status"]).to eq("completed")
      expect(json["ai_summary"]).to include("Great workout!")
    end

    it "returns 404 for another user's workout" do
      other_workout =
        Workout.create!(
          user: users(:jane),
          workout_type: :strength,
          started_at: 1.hour.ago,
          ended_at: Time.current
        )

      get ai_feedback_status_workout_path(other_workout), as: :json

      expect(response).to have_http_status(:not_found)
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

  describe "GET /workouts/:id/notes_modal" do
    let!(:workout) do
      Workout.create!(
        user: user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        ended_at: Time.current,
        workout_routine_day: workout_routine_days(:push_day)
      )
    end

    it "returns the notes modal" do
      get notes_modal_workout_path(workout)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Workout Notes")
    end
  end

  describe "PATCH /workouts/:id/update_notes" do
    let!(:workout) do
      Workout.create!(
        user: user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        ended_at: Time.current,
        workout_routine_day: workout_routine_days(:push_day)
      )
    end

    it "updates the workout notes" do
      patch update_notes_workout_path(workout),
            params: {
              workout: {
                notes: "Great workout today!"
              }
            }

      workout.reload
      expect(workout.notes).to eq("Great workout today!")
    end

    it "returns turbo stream response" do
      patch update_notes_workout_path(workout),
            params: {
              workout: {
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
