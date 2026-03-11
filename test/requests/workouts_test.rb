require "test_helper"

class WorkoutsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
    sign_in(@user)
  end

  test "GET /workouts returns success" do
    get workouts_path
    assert_response :success
  end

  test "GET /workouts/new returns success" do
    get new_workout_path
    assert_response :success
  end

  test "POST /workouts with a workout routine day creates a strength workout" do
    assert_difference "Workout.count", 1 do
      post workouts_path,
           params: {
             workout: {
               workout_type: "strength",
               workout_routine_day_id: workout_routine_days(:push_day).id
             }
           }
    end

    workout = Workout.last
    assert workout.strength?
    assert_equal workout_routine_days(:push_day), workout.workout_routine_day
    assert_equal @user, workout.user
    assert_redirected_to workout_path(workout)
  end

  test "POST /workouts without a workout routine day creates a strength workout without a routine" do
    assert_difference "Workout.count", 1 do
      post workouts_path,
           params: {
             workout: {
               workout_type: "strength",
               workout_routine_day_id: nil
             }
           }
    end

    workout = Workout.last
    assert workout.strength?
    assert_nil workout.workout_routine_day
    assert_equal @user, workout.user
    assert_redirected_to workout_path(workout)
  end

  test "POST /workouts with run workout type creates a run workout" do
    assert_difference "Workout.count", 1 do
      post workouts_path,
           params: {
             workout: {
               workout_type: "run",
               started_at: Date.today,
               distance: 5000,
               time_in_seconds: "30:00"
             }
           }
    end

    workout = Workout.last
    assert workout.run?
    assert_equal 5000, workout.distance
    assert_equal 1800, workout.time_in_seconds
    assert_redirected_to workouts_path
  end

  test "POST /workouts does not create when user already has an active workout" do
    Workout.create!(
      user: @user,
      workout_type: :strength,
      started_at: 1.hour.ago,
      workout_routine_day: workout_routine_days(:push_day)
    )

    assert_no_difference "Workout.count" do
      post workouts_path,
           params: {
             workout: {
               workout_type: "strength",
               workout_routine_day_id: workout_routine_days(:pull_day).id
             }
           }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "You already have an active workout"
  end

  test "POST /workouts/:id/stop ends the workout and redirects to summary" do
    workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        workout_routine_day: workout_routine_days(:push_day)
      )
    assert_nil workout.ended_at

    post stop_workout_path(workout)

    workout.reload
    assert workout.ended_at.present?
    assert_redirected_to summary_workout_path(workout)
  end

  test "POST /workouts/:id/stop ends all active workout sets" do
    workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        workout_routine_day: workout_routine_days(:push_day)
      )
    workout_set =
      workout.workout_sets.create!(
        exercise: exercises(:bench_press),
        started_at: 30.minutes.ago
      )

    post stop_workout_path(workout)

    workout_set.reload
    assert workout_set.ended_at.present?
  end

  test "POST /workouts/:id/stop creates personal records when workout ends" do
    @user.personal_records.destroy_all
    workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        workout_routine_day: workout_routine_days(:push_day)
      )
    workout_set =
      workout.workout_sets.create!(
        exercise: exercises(:bench_press),
        started_at: 30.minutes.ago
      )
    workout_set.workout_reps.create!(weight: 100, reps: 10)

    assert_difference "PersonalRecord.count", 2 do
      post stop_workout_path(workout)
    end
  end

  test "POST /workouts/:id/stop stores PR IDs in session for summary page" do
    @user.personal_records.destroy_all
    workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        workout_routine_day: workout_routine_days(:push_day)
      )
    workout_set =
      workout.workout_sets.create!(
        exercise: exercises(:bench_press),
        started_at: 30.minutes.ago
      )
    workout_set.workout_reps.create!(weight: 100, reps: 10)

    post stop_workout_path(workout)

    assert session[:workout_summary_prs].present?
    assert_equal 2, session[:workout_summary_prs].size
  end

  test "GET /workouts/:id/summary returns success for completed workout" do
    workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        ended_at: Time.current,
        workout_routine_day: workout_routine_days(:push_day)
      )
    get summary_workout_path(workout)
    assert_response :success
  end

  test "GET /workouts/:id/summary redirects to workouts_path for incomplete workout" do
    workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        workout_routine_day: workout_routine_days(:push_day)
      )
    get summary_workout_path(workout)
    assert_redirected_to workouts_path
  end

  test "GET /workouts/:id/summary returns 404 for another user's workout" do
    other_workout =
      Workout.create!(
        user: users(:jane),
        workout_type: :strength,
        started_at: 1.hour.ago,
        ended_at: Time.current
      )
    get summary_workout_path(other_workout)
    assert_response :not_found
  end

  test "GET /workouts/:id/summary displays total volume" do
    workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        ended_at: Time.current,
        workout_routine_day: workout_routine_days(:push_day)
      )
    workout_set =
      workout.workout_sets.create!(
        exercise: exercises(:bench_press),
        started_at: 30.minutes.ago
      )
    workout_set.workout_reps.create!(weight: 100, reps: 10)

    get summary_workout_path(workout)
    assert_includes response.body, "Total Volume"
    assert_match(/1000|1t/, response.body)
  end

  test "GET /workouts/:id/summary displays muscles worked" do
    workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        ended_at: Time.current,
        workout_routine_day: workout_routine_days(:push_day)
      )
    workout.workout_sets.create!(
      exercise: exercises(:bench_press),
      started_at: 30.minutes.ago
    )

    get summary_workout_path(workout)
    assert_includes response.body, "Chest"
  end

  test "GET /workouts/:id/summary displays workout complete title" do
    workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        ended_at: Time.current,
        workout_routine_day: workout_routine_days(:push_day)
      )
    get summary_workout_path(workout)
    assert_includes response.body, "Workout Complete!"
  end

  test "GET /workouts/:id/summary displays routine information" do
    workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        ended_at: Time.current,
        workout_routine_day: workout_routine_days(:push_day)
      )
    get summary_workout_path(workout)
    assert_includes response.body, "Push Day"
    assert_includes response.body, "Push Pull Legs"
  end

  test "POST /workouts/:id/stop with configured AI trainer enqueues GenerateAiWorkoutFeedbackJob" do
    @user.update!(
      ai_provider: "gemini",
      ai_model: "gemini-2.0-flash",
      ai_api_key: "test-key"
    )
    @user.ai_trainer.update!(
      status: :completed,
      trainer_profile: "Trainer profile."
    )

    workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        workout_routine_day: workout_routine_days(:push_day)
      )

    assert_enqueued_with(job: GenerateAiWorkoutFeedbackJob) do
      post stop_workout_path(workout)
    end
  end

  test "POST /workouts/:id/stop without AI trainer does not enqueue GenerateAiWorkoutFeedbackJob" do
    @user.ai_trainer&.destroy

    workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        workout_routine_day: workout_routine_days(:push_day)
      )

    assert_no_enqueued_jobs(only: GenerateAiWorkoutFeedbackJob) do
      post stop_workout_path(workout)
    end
  end

  test "POST /workouts/:id/pause pauses the workout" do
    workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        workout_routine_day: workout_routine_days(:push_day)
      )
    assert_nil workout.paused_at

    post pause_workout_path(workout)

    workout.reload
    assert workout.paused_at.present?
    assert_redirected_to workout_path(workout)
  end

  test "POST /workouts/:id/resume resumes the workout" do
    workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        paused_at: 10.minutes.ago,
        workout_routine_day: workout_routine_days(:push_day)
      )

    post resume_workout_path(workout)

    workout.reload
    assert_nil workout.paused_at
    assert workout.total_paused_seconds > 0
    assert_redirected_to workout_path(workout)
  end

  test "DELETE /workouts/:id deletes the workout" do
    workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        ended_at: Time.current,
        workout_routine_day: workout_routine_days(:push_day)
      )

    assert_difference "Workout.count", -1 do
      delete workout_path(workout)
    end
    assert_redirected_to workouts_path
  end

  test "GET /workouts/:id renders workout with bodyweight exercise" do
    workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        workout_routine_day: workout_routine_days(:push_day)
      )
    workout.workout_sets.create!(
      exercise: exercises(:pull_up),
      started_at: 30.minutes.ago
    )

    get workout_path(workout)
    assert_response :success
    assert_includes response.body, "Pull-Up"
  end

  test "GET /workouts/:id renders workout with banded exercise" do
    workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        workout_routine_day: workout_routine_days(:push_day)
      )
    workout.workout_sets.create!(
      exercise: exercises(:banded_squat),
      started_at: 30.minutes.ago
    )

    get workout_path(workout)
    assert_response :success
    assert_includes response.body, "Banded Squat"
  end

  test "GET /workouts/:id/notes_modal returns the notes modal" do
    workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        ended_at: Time.current,
        workout_routine_day: workout_routine_days(:push_day)
      )

    get notes_modal_workout_path(workout)
    assert_response :success
    assert_includes response.body, "Workout Notes"
  end

  test "PATCH /workouts/:id/update_notes updates the workout notes" do
    workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        ended_at: Time.current,
        workout_routine_day: workout_routine_days(:push_day)
      )

    patch update_notes_workout_path(workout),
          params: {
            workout: {
              notes: "Great workout today!"
            }
          }
    workout.reload
    assert_equal "Great workout today!", workout.notes
  end

  test "GET /workouts/:id/edit returns success" do
    workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        ended_at: Time.current,
        workout_routine_day: workout_routine_days(:push_day)
      )

    get edit_workout_path(workout)
    assert_response :success
  end

  test "PATCH /workouts/:id updates workout attributes" do
    workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        ended_at: Time.current,
        workout_routine_day: workout_routine_days(:push_day)
      )

    patch workout_path(workout),
          params: {
            workout: {
              notes: "Updated notes for workout"
            }
          }
    assert_redirected_to workout_path(workout)
    workout.reload
    assert_equal "Updated notes for workout", workout.notes
  end

  test "PATCH /workouts/:id with invalid params renders edit" do
    workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        ended_at: Time.current,
        workout_routine_day: workout_routine_days(:push_day)
      )

    Workout.any_instance.stubs(:update).returns(false)

    patch workout_path(workout), params: { workout: { notes: "test" } }
    assert_response :unprocessable_entity
  end

  test "GET /workouts/:id/modal returns success without layout" do
    workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        ended_at: Time.current,
        workout_routine_day: workout_routine_days(:push_day)
      )

    get modal_workout_path(workout)
    assert_response :success
  end

  test "POST /workouts with run workout type and hours:minutes:seconds time" do
    assert_difference "Workout.count", 1 do
      post workouts_path,
           params: {
             workout: {
               workout_type: "run",
               started_at: Date.today,
               distance: 10_000,
               time_in_seconds: "1:05:30"
             }
           }
    end

    workout = Workout.last
    assert workout.run?
    assert_equal 10_000, workout.distance
    assert_equal 3930, workout.time_in_seconds
    assert_redirected_to workouts_path
  end

  test "POST /workouts/:id/stop without AI configured does not enqueue AI feedback job" do
    @user.update!(ai_provider: nil, ai_model: nil, ai_api_key: nil)
    @user.ai_trainer&.update!(status: :pending, trainer_profile: nil)

    workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        workout_routine_day: workout_routine_days(:push_day)
      )

    assert_no_enqueued_jobs(only: GenerateAiWorkoutFeedbackJob) do
      post stop_workout_path(workout)
    end
    assert_redirected_to summary_workout_path(workout)
  end

  test "GET /workouts with month param returns success" do
    get workouts_path, params: { month: "2025-06-01" }
    assert_response :success
  end

  test "GET /workouts/new redirects when active workout exists" do
    Workout.create!(
      user: @user,
      workout_type: :strength,
      started_at: 1.hour.ago,
      workout_routine_day: workout_routine_days(:push_day)
    )

    get new_workout_path
    assert_response :redirect
  end

  test "PATCH /workouts/:id/update_notes returns turbo stream response" do
    workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        ended_at: Time.current,
        workout_routine_day: workout_routine_days(:push_day)
      )

    patch update_notes_workout_path(workout),
          params: {
            workout: {
              notes: "Test notes"
            }
          },
          headers: {
            "Accept" => "text/vnd.turbo-stream.html"
          }
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "GET /workouts/:id/summary marks AI feedback as viewed" do
    @user.update!(
      ai_provider: "gemini",
      ai_model: "gemini-2.0-flash",
      ai_api_key: "test-key"
    )
    ai_trainer = @user.ai_trainer
    ai_trainer.update!(status: :completed, trainer_profile: "Profile.")

    workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        ended_at: Time.current,
        workout_routine_day: workout_routine_days(:push_day)
      )

    activity =
      AiTrainerActivity.create!(
        user: @user,
        ai_trainer: ai_trainer,
        workout: workout,
        activity_type: :workout_review,
        status: :completed,
        content: "Great workout!"
      )

    assert_nil activity.viewed_at

    get summary_workout_path(workout)
    assert_response :success

    activity.reload
    assert activity.viewed?
  end

  test "PATCH /workouts/:id/mark_ai_viewed marks AI feedback as viewed" do
    @user.update!(
      ai_provider: "gemini",
      ai_model: "gemini-2.0-flash",
      ai_api_key: "test-key"
    )
    ai_trainer = @user.ai_trainer
    ai_trainer.update!(status: :completed, trainer_profile: "Profile.")

    workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        ended_at: Time.current,
        workout_routine_day: workout_routine_days(:push_day)
      )

    activity =
      AiTrainerActivity.create!(
        user: @user,
        ai_trainer: ai_trainer,
        workout: workout,
        activity_type: :workout_review,
        status: :completed,
        content: "Great workout!"
      )

    assert_nil activity.viewed_at

    patch mark_ai_viewed_workout_path(workout)
    assert_response :ok

    activity.reload
    assert activity.viewed?
  end

  test "PATCH /workouts/:id/apply_ai_suggestion applies suggestion to routine exercise" do
    @user.update!(
      ai_provider: "gemini",
      ai_model: "gemini-2.0-flash",
      ai_api_key: "test-key"
    )
    ai_trainer = @user.ai_trainer
    ai_trainer.update!(status: :completed, trainer_profile: "Profile.")

    workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        ended_at: Time.current,
        workout_routine_day: workout_routine_days(:push_day)
      )

    rde = workout_routine_day_exercises(:push_day_bench)
    suggestions = [
      {
        "exercise" => "Bench Press",
        "field" => "sets",
        "value" => "4-5",
        "reason" => "You completed all sets easily",
        "workout_routine_day_exercise_id" => rde.id
      }
    ]

    AiTrainerActivity.create!(
      user: @user,
      ai_trainer: ai_trainer,
      workout: workout,
      activity_type: :workout_review,
      status: :completed,
      content: "Good workout",
      suggestions: suggestions.to_json
    )

    patch apply_ai_suggestion_workout_path(workout),
          params: {
            suggestion_index: 0
          },
          headers: {
            "Accept" => "text/vnd.turbo-stream.html"
          }

    assert_response :success
    rde.reload
    assert_equal "4-5", rde.sets

    activity = workout.ai_trainer_activity.reload
    assert activity.parsed_suggestions[0]["applied"]
  end

  test "PATCH /workouts/:id/apply_ai_suggestion returns not_found for invalid index" do
    workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        ended_at: Time.current
      )

    patch apply_ai_suggestion_workout_path(workout),
          params: {
            suggestion_index: 99
          }

    assert_response :not_found
  end
end
