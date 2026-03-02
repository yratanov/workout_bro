require "test_helper"

class Admin::AiLogsTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = users(:john)
    @regular_user = users(:jane)
  end

  # === as admin ===

  test "GET /admin/ai_logs returns success as admin" do
    sign_in(@admin_user)
    get admin_ai_logs_path
    assert_response :success
  end

  test "GET /admin/ai_logs displays the AI logs page as admin" do
    sign_in(@admin_user)
    get admin_ai_logs_path
    assert_includes response.body, I18n.t("admin.ai_logs.index.ai_logs")
  end

  test "GET /admin/ai_logs displays AI logs when present as admin" do
    sign_in(@admin_user)
    AiLog.create!(
      user: @admin_user,
      action: "create_trainer",
      model: "gemini-2.0-flash",
      prompt: "Test prompt",
      response: "Test response",
      duration_ms: 1234
    )

    get admin_ai_logs_path
    assert_includes response.body, "create_trainer"
    assert_includes response.body, "gemini-2.0-flash"
    assert_includes response.body, "1234ms"
  end

  test "GET /admin/ai_logs displays token count badge when present as admin" do
    sign_in(@admin_user)
    AiLog.create!(
      user: @admin_user,
      action: "create_trainer",
      model: "gemini-2.0-flash",
      total_tokens: 450
    )

    get admin_ai_logs_path
    assert_includes response.body, "450"
    assert_includes response.body, I18n.t("admin.ai_logs.index.tokens")
  end

  test "GET /admin/ai_logs displays AI logs in descending order as admin" do
    sign_in(@admin_user)
    AiLog.create!(
      user: @admin_user,
      action: "old_action",
      model: "gemini-2.0-flash",
      created_at: 1.hour.ago
    )
    AiLog.create!(
      user: @admin_user,
      action: "new_action",
      model: "gemini-2.0-flash",
      created_at: Time.current
    )

    get admin_ai_logs_path
    assert response.body.index("new_action") < response.body.index("old_action")
  end

  test "GET /admin/ai_logs displays error badge for failed requests as admin" do
    sign_in(@admin_user)
    AiLog.create!(
      user: @admin_user,
      action: "create_trainer",
      model: "gemini-2.0-flash",
      error: "API rate limit exceeded"
    )

    get admin_ai_logs_path
    assert_includes response.body, I18n.t("admin.ai_logs.index.failed")
    assert_includes response.body, "API rate limit exceeded"
  end

  test "GET /admin/ai_logs displays user email as admin" do
    sign_in(@admin_user)
    AiLog.create!(
      user: @admin_user,
      action: "workout_feedback",
      model: "gemini-2.0-flash"
    )

    get admin_ai_logs_path
    assert_includes response.body, @admin_user.email_address
  end

  test "GET /admin/ai_logs displays expandable prompt section as admin" do
    sign_in(@admin_user)
    AiLog.create!(
      user: @admin_user,
      action: "create_trainer",
      model: "gemini-2.0-flash",
      prompt: "Generate a trainer profile"
    )

    get admin_ai_logs_path
    assert_includes response.body, I18n.t("admin.ai_logs.index.show_prompt")
    assert_includes response.body, "Generate a trainer profile"
  end

  test "GET /admin/ai_logs displays expandable response section as admin" do
    sign_in(@admin_user)
    AiLog.create!(
      user: @admin_user,
      action: "create_trainer",
      model: "gemini-2.0-flash",
      response: "Here is your trainer"
    )

    get admin_ai_logs_path
    assert_includes response.body, I18n.t("admin.ai_logs.index.show_response")
    assert_includes response.body, "Here is your trainer"
  end

  test "GET /admin/ai_logs shows empty state when no logs as admin" do
    sign_in(@admin_user)
    get admin_ai_logs_path
    assert_includes response.body, I18n.t("admin.ai_logs.index.no_logs")
  end

  test "GET /admin/ai_logs paginates logs as admin" do
    sign_in(@admin_user)
    30.times do |i|
      AiLog.create!(
        user: @admin_user,
        action: "action_#{i}",
        model: "gemini-2.0-flash"
      )
    end

    get admin_ai_logs_path
    assert_includes response.body, "action_29"
    assert_not_includes response.body, "action_0"
  end

  # === as regular user ===

  test "GET /admin/ai_logs redirects as regular user" do
    sign_in(@regular_user)
    get admin_ai_logs_path
    assert_redirected_to root_path
  end

  test "GET /admin/ai_logs shows admin required flash message as regular user" do
    sign_in(@regular_user)
    get admin_ai_logs_path
    follow_redirect!
    assert_includes response.body,
                    I18n.t("controllers.application.admin_required")
  end

  # === when not authenticated ===

  test "GET /admin/ai_logs redirects to login when not authenticated" do
    get admin_ai_logs_path
    assert_redirected_to new_session_path
  end
end
