require "test_helper"

class Settings::AiTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
    sign_in(@user)
  end

  test "GET /settings/ai returns success" do
    get settings_ai_path
    assert_response :success
  end

  test "GET /settings/ai displays the AI settings form" do
    get settings_ai_path
    assert_includes response.body, "AI Settings"
  end

  test "GET /settings/ai displays the AI trainer section" do
    get settings_ai_path
    assert_includes response.body, "AI Trainer"
  end

  test "GET /settings/ai shows warning when AI is not configured" do
    get settings_ai_path
    assert_includes response.body, "configure your AI provider"
  end

  test "GET /settings/ai does not show warning when AI is configured" do
    @user.update!(
      ai_provider: "gemini",
      ai_model: "gemini-2.5-flash",
      ai_api_key: "test-key"
    )
    get settings_ai_path
    assert_not_includes response.body, "configure your AI provider"
  end

  test "PATCH /settings/ai updates ai_provider and ai_model" do
    patch settings_ai_path,
          params: {
            user: {
              ai_provider: "gemini",
              ai_model: "gemini-2.5-pro"
            }
          }
    @user.reload
    assert_equal "gemini", @user.ai_provider
    assert_equal "gemini-2.5-pro", @user.ai_model
    assert_redirected_to settings_ai_path
  end

  test "PATCH /settings/ai clears ai_provider and ai_model" do
    @user.update!(ai_provider: "gemini", ai_model: "gemini-2.5-pro")
    patch settings_ai_path, params: { user: { ai_provider: "", ai_model: "" } }
    @user.reload
    assert_equal "", @user.ai_provider
    assert_equal "", @user.ai_model
  end

  test "PATCH /settings/ai saves the API key" do
    patch settings_ai_path,
          params: {
            user: {
              ai_provider: "gemini",
              ai_model: "gemini-2.5-pro",
              ai_api_key: "test-api-key-123"
            }
          }
    @user.reload
    assert_equal "test-api-key-123", @user.ai_api_key
  end

  test "PATCH /settings/ai does not overwrite API key when blank" do
    @user.update!(ai_api_key: "existing-key")
    patch settings_ai_path,
          params: {
            user: {
              ai_provider: "gemini",
              ai_api_key: ""
            }
          }
    @user.reload
    assert_equal "existing-key", @user.ai_api_key
  end

  test "PATCH /settings/ai displays success message" do
    patch settings_ai_path,
          params: {
            user: {
              ai_provider: "gemini",
              ai_model: "gemini-2.5-flash"
            }
          }
    follow_redirect!
    assert_includes response.body, "AI settings updated successfully"
  end

  test "POST /settings/ai/create_trainer creates an ai_trainer and enqueues job" do
    assert_enqueued_with(job: CreateAiTrainerJob) do
      post create_trainer_settings_ai_path,
           params: {
             ai_trainer: {
               approach: "balanced",
               communication_style: "motivational",
               goal_general_fitness: "1",
               train_on_existing_data: "1"
             }
           }
    end
    assert_redirected_to settings_ai_path
    assert @user.reload.ai_trainer.present?
    assert @user.ai_trainer.balanced?
    assert @user.ai_trainer.motivational?
  end

  test "POST /settings/ai/create_trainer updates existing ai_trainer" do
    post create_trainer_settings_ai_path,
         params: {
           ai_trainer: {
             approach: "tough_love",
             communication_style: "detailed"
           }
         }
    @user.ai_trainer.reload
    assert @user.ai_trainer.tough_love?
    assert @user.ai_trainer.detailed?
  end

  test "GET /settings/ai/trainer_status returns trainer status as JSON" do
    @user.ai_trainer.update!(status: :in_progress)
    get trainer_status_settings_ai_path, as: :json
    assert_response :success
    data = response.parsed_body
    assert_equal "in_progress", data["status"]
  end

  test "GET /settings/ai/trainer_status returns completed status for default trainer" do
    get trainer_status_settings_ai_path, as: :json
    data = response.parsed_body
    assert_equal "completed", data["status"]
  end

  test "GET /settings/ai/trainer_status returns error_details on failure" do
    @user.ai_trainer.update!(
      status: :failed,
      error_details: {
        message: "API key invalid"
      }
    )
    get trainer_status_settings_ai_path, as: :json
    data = response.parsed_body
    assert_equal "failed", data["status"]
    assert_equal "API key invalid", data["error_details"]["message"]
  end

  test "GET /settings/ai/trainer_profile_modal returns success" do
    get trainer_profile_modal_settings_ai_path
    assert_response :success
    assert_includes response.body, "trainer_profile"
  end

  test "GET /settings/ai/trainer_status returns not_found when user has no trainer" do
    @user.ai_trainer.destroy
    get trainer_status_settings_ai_path, as: :json
    assert_response :success
    data = response.parsed_body
    assert_equal "not_found", data["status"]
  end

  test "PATCH /settings/ai update_trainer with no trainer returns alert" do
    @user.ai_trainer.destroy

    patch update_trainer_settings_ai_path,
          params: {
            ai_trainer: {
              trainer_profile: "Some profile"
            }
          }
    assert_redirected_to settings_ai_path
  end

  test "POST /settings/ai/create_trainer when ai_trainer save fails redirects with alert" do
    AiTrainer.any_instance.stubs(:save).returns(false)

    post create_trainer_settings_ai_path,
         params: {
           ai_trainer: {
             approach: "balanced",
             communication_style: "motivational"
           }
         }
    assert_redirected_to settings_ai_path
    follow_redirect!
    assert_includes response.body, "Failed to start AI trainer creation"
  end

  test "PATCH /settings/ai/update_trainer updates trainer profile" do
    patch update_trainer_settings_ai_path,
          params: {
            ai_trainer: {
              trainer_profile: "Updated trainer profile content."
            }
          }
    assert_redirected_to settings_ai_path
    @user.ai_trainer.reload
    assert_equal "Updated trainer profile content.", @user.ai_trainer.trainer_profile
  end

  test "PATCH /settings/ai/update_trainer with failure redirects with alert" do
    AiTrainer.any_instance.stubs(:update).returns(false)

    patch update_trainer_settings_ai_path,
          params: {
            ai_trainer: {
              trainer_profile: ""
            }
          }
    assert_redirected_to settings_ai_path
  end

  test "GET /settings/ai redirects to login when not authenticated" do
    delete session_path
    get settings_ai_path
    assert_redirected_to new_session_path
  end
end
