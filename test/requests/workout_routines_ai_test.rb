require "test_helper"

class WorkoutRoutinesAiTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
    @user.update!(
      ai_provider: "gemini",
      ai_model: "gemini-2.0-flash",
      ai_api_key: "test-key"
    )
    sign_in(@user)
  end

  test "GET /workout_routines/ai_new with configured AI trainer returns success" do
    setup_ai_trainer
    get ai_new_workout_routines_path
    assert_response :success
  end

  test "GET /workout_routines/ai_new shows the questionnaire form" do
    setup_ai_trainer
    get ai_new_workout_routines_path
    assert_includes response.body, "frequency"
    assert_includes response.body, "split_type"
  end

  test "GET /workout_routines/ai_new without configured AI trainer redirects to index" do
    user_without_ai = users(:jane)
    sign_in(user_without_ai)
    get ai_new_workout_routines_path
    assert_redirected_to workout_routines_path
  end

  test "POST /workout_routines/ai_create creates a workout routine with pending ai_status" do
    setup_ai_trainer
    assert_difference "WorkoutRoutine.count", 1 do
      post ai_create_workout_routines_path, params: ai_params
    end
    routine = WorkoutRoutine.last
    assert_equal "pending", routine.ai_status
  end

  test "POST /workout_routines/ai_create enqueues AiRoutineSuggestionJob" do
    setup_ai_trainer
    assert_enqueued_with(job: AiRoutineSuggestionJob) do
      post ai_create_workout_routines_path, params: ai_params
    end
  end

  test "POST /workout_routines/ai_create redirects to the new routine" do
    setup_ai_trainer
    post ai_create_workout_routines_path, params: ai_params
    assert_redirected_to WorkoutRoutine.last
  end

  test "POST /workout_routines/ai_create without configured AI trainer redirects to index" do
    user_without_ai = users(:jane)
    sign_in(user_without_ai)
    post ai_create_workout_routines_path, params: ai_params
    assert_redirected_to workout_routines_path
  end

  test "POST /workout_routines/ai_create without configured AI trainer does not create a routine" do
    user_without_ai = users(:jane)
    sign_in(user_without_ai)
    assert_no_difference "WorkoutRoutine.count" do
      post ai_create_workout_routines_path, params: ai_params
    end
  end

  test "GET /workout_routines/:id/ai_status returns pending status when generating" do
    routine = @user.workout_routines.create!(name: "Test", ai_status: :pending)
    get ai_status_workout_routine_path(routine)
    assert_equal "pending", response.parsed_body["status"]
  end

  test "GET /workout_routines/:id/ai_status returns completed status when completed" do
    routine = @user.workout_routines.create!(name: "Test", ai_status: nil)
    get ai_status_workout_routine_path(routine)
    assert_equal "completed", response.parsed_body["status"]
  end

  test "GET /workout_routines/:id/ai_status returns failed status when failed" do
    routine = @user.workout_routines.create!(name: "Test", ai_status: :failed)
    get ai_status_workout_routine_path(routine)
    assert_equal "failed", response.parsed_body["status"]
  end

  private

  def setup_ai_trainer
    @user.ai_trainer.update!(
      status: :completed,
      trainer_profile: "A balanced fitness trainer."
    )
  end

  def ai_params
    {
      frequency: "3",
      split_type: "Push/Pull/Legs",
      experience_level: "Intermediate",
      additional_context: "No injuries"
    }
  end
end
