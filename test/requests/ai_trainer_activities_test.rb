require "test_helper"

class AiTrainerActivitiesTest < ActionDispatch::IntegrationTest
  setup { @user = users(:john) }

  test "GET /ai returns success when authenticated" do
    sign_in(@user)
    get ai_trainer_activities_path
    assert_response :success
  end

  test "GET /ai shows completed activities" do
    sign_in(@user)
    get ai_trainer_activities_path
    assert_includes response.body, "Workout Feedback"
    assert_includes response.body, "Weekly Report"
  end

  test "GET /ai does not show pending activities" do
    sign_in(@user)
    get ai_trainer_activities_path
    assert_includes response.body, "Training Review"
  end

  test "GET /ai redirects to login when not authenticated" do
    get ai_trainer_activities_path
    assert_redirected_to new_session_path
  end

  test "GET /ai/:id shows the activity" do
    sign_in(@user)
    activity = ai_trainer_activities(:johns_workout_review)
    get ai_trainer_activity_path(activity)
    assert_response :success
    assert_includes response.body, "Good volume progression"
  end

  test "GET /ai/:id marks the activity as viewed" do
    sign_in(@user)
    activity = ai_trainer_activities(:johns_workout_review)
    assert_nil activity.viewed_at

    get ai_trainer_activity_path(activity)

    activity.reload
    assert activity.viewed_at.present?
  end

  test "GET /ai/:id does not update viewed_at if already viewed" do
    sign_in(@user)
    activity = ai_trainer_activities(:johns_full_review)
    original_time = activity.viewed_at

    get ai_trainer_activity_path(activity)

    activity.reload
    assert_in_delta original_time.to_f, activity.viewed_at.to_f, 1
  end

  test "GET /ai/:id shows workout link for workout_review activities" do
    sign_in(@user)
    activity = ai_trainer_activities(:johns_workout_review)
    get ai_trainer_activity_path(activity)
    assert_includes response.body, "View Workout"
  end

  test "GET /ai/:id shows week range for weekly_report activities" do
    sign_in(@user)
    activity = ai_trainer_activities(:johns_weekly_report)
    get ai_trainer_activity_path(activity)
    assert_response :success
  end

  test "GET /ai/:id shows chat form for completed activities" do
    sign_in(@user)
    activity = ai_trainer_activities(:johns_workout_review)
    get ai_trainer_activity_path(activity)
    assert_response :success
    assert_includes response.body, "ai_chat_response_#{activity.id}"
    assert_includes response.body, "ask_ai"
  end

  test "POST /ai/:id/ask_ai enqueues followup job" do
    sign_in(@user)
    @user.update!(
      ai_provider: "gemini",
      ai_model: "gemini-2.0-flash",
      ai_api_key: "test-key"
    )
    @user.ai_trainer.update!(status: :completed, trainer_profile: "Profile.")

    activity = ai_trainer_activities(:johns_workout_review)

    assert_enqueued_with(job: GenerateAiFollowupJob) do
      post ask_ai_ai_trainer_activity_path(activity),
           params: {
             question: "Can you explain more?"
           }
    end

    assert_response :ok
  end

  test "POST /ai/:id/ask_ai returns 422 with blank question" do
    sign_in(@user)
    activity = ai_trainer_activities(:johns_workout_review)

    post ask_ai_ai_trainer_activity_path(activity), params: { question: "" }

    assert_response :unprocessable_entity
  end

  test "POST /ai/:id/ask_ai returns 422 for non-completed activity" do
    sign_in(@user)
    activity = ai_trainer_activities(:johns_workout_review)
    activity.update!(status: :pending)

    post ask_ai_ai_trainer_activity_path(activity),
         params: {
           question: "Tell me more"
         }

    assert_response :unprocessable_entity
  end
end
