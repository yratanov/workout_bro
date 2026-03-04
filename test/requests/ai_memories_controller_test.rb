require "test_helper"

class AiMemoriesControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:john) }

  test "GET /ai/memories returns success when authenticated" do
    sign_in(@user)
    get ai_memories_path
    assert_response :success
  end

  test "GET /ai/memories displays memories grouped by category" do
    sign_in(@user)
    get ai_memories_path
    assert_includes response.body, "Typically trains 3-4 times per week"
    assert_includes response.body, "Has access to a full gym"
  end

  test "GET /ai/memories redirects when not authenticated" do
    get ai_memories_path
    assert_redirected_to new_session_path
  end

  test "DELETE /ai/memories/:id destroys memory" do
    sign_in(@user)
    memory = ai_memories(:johns_schedule)
    assert_difference("AiMemory.count", -1) { delete ai_memory_path(memory) }
    assert_redirected_to ai_memories_path
  end

  test "DELETE /ai/memories/:id cannot delete other user's memory" do
    sign_in(users(:jane))
    memory = ai_memories(:johns_schedule)
    assert_no_difference("AiMemory.count") { delete ai_memory_path(memory) }
    assert_response :not_found
  end

  test "POST /ai/memories/generate enqueues bootstrap job and renders loading state" do
    sign_in(@user)
    @user.update!(
      ai_provider: "gemini",
      ai_model: "gemini-2.0-flash",
      ai_api_key: "test-key"
    )

    assert_enqueued_with(job: BootstrapAiMemoriesJob) do
      post generate_ai_memories_path
    end
    assert_response :success
    assert_includes response.body, I18n.t("ai_memories.index.generating")
    assert_includes response.body, "ai_memory_generation_status"
    assert_includes response.body, "animate-spin"
  end

  test "POST /ai/memories/generate redirects with alert when AI not configured" do
    sign_in(@user)
    @user.update_columns(ai_provider: nil, ai_model: nil, ai_api_key: nil)

    assert_no_enqueued_jobs(only: BootstrapAiMemoriesJob) do
      post generate_ai_memories_path
    end
    assert_redirected_to ai_memories_path
    assert_equal I18n.t("controllers.ai_memories.not_configured"), flash[:alert]
  end

  test "POST /ai/memories/generate redirects when not authenticated" do
    post generate_ai_memories_path
    assert_redirected_to new_session_path
  end
end
