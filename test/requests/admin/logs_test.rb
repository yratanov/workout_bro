require "test_helper"

class Admin::LogsTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = users(:john)
    @regular_user = users(:jane)
  end

  # === as admin ===

  test "GET /admin/logs returns success as admin" do
    sign_in(@admin_user)
    get admin_logs_path
    assert_response :success
  end

  test "GET /admin/logs displays the error logs page as admin" do
    sign_in(@admin_user)
    get admin_logs_path
    assert_includes response.body, I18n.t("admin.logs.show.error_logs")
  end

  test "GET /admin/logs displays error logs when present as admin" do
    sign_in(@admin_user)
    ErrorLog.create!(
      error_class: "StandardError",
      message: "Test error message",
      severity: :error,
      source: "test"
    )

    get admin_logs_path
    assert_includes response.body, "StandardError"
    assert_includes response.body, "Test error message"
  end

  test "GET /admin/logs displays error logs in descending order by created_at as admin" do
    sign_in(@admin_user)
    ErrorLog.create!(
      error_class: "OldError",
      message: "Old error",
      severity: :error,
      created_at: 1.hour.ago
    )
    ErrorLog.create!(
      error_class: "NewError",
      message: "New error",
      severity: :error,
      created_at: Time.current
    )

    get admin_logs_path
    assert response.body.index("NewError") < response.body.index("OldError")
  end

  test "GET /admin/logs displays severity badge as admin" do
    sign_in(@admin_user)
    ErrorLog.create!(
      error_class: "TestError",
      message: "Test",
      severity: :error
    )

    get admin_logs_path
    assert_includes response.body, I18n.t("admin.logs.show.severities.error")
  end

  test "GET /admin/logs displays source when present as admin" do
    sign_in(@admin_user)
    ErrorLog.create!(
      error_class: "TestError",
      message: "Test",
      severity: :error,
      source: "custom_source"
    )

    get admin_logs_path
    assert_includes response.body, "custom_source"
  end

  test "GET /admin/logs displays backtrace toggle when backtrace present as admin" do
    sign_in(@admin_user)
    ErrorLog.create!(
      error_class: "TestError",
      message: "Test",
      severity: :error,
      backtrace: %w[/app/test.rb:1 /app/test.rb:2]
    )

    get admin_logs_path
    assert_includes response.body, I18n.t("admin.logs.show.show_backtrace")
    assert_includes response.body, "/app/test.rb:1"
  end

  test "GET /admin/logs shows empty state when no logs as admin" do
    sign_in(@admin_user)
    get admin_logs_path
    assert_includes response.body, I18n.t("admin.logs.show.no_logs")
  end

  test "GET /admin/logs limits to 100 logs as admin" do
    sign_in(@admin_user)
    105.times do |i|
      ErrorLog.create!(
        error_class: "Error#{i}",
        message: "Message #{i}",
        severity: :error
      )
    end

    get admin_logs_path
    assert_not_includes response.body, "Error0"
    assert_includes response.body, "Error104"
  end

  # === as regular user ===

  test "GET /admin/logs redirects as regular user" do
    sign_in(@regular_user)
    get admin_logs_path
    assert_redirected_to root_path
  end

  test "GET /admin/logs shows admin required flash message as regular user" do
    sign_in(@regular_user)
    get admin_logs_path
    follow_redirect!
    assert_includes response.body,
                    I18n.t("controllers.application.admin_required")
  end

  # === when not authenticated ===

  test "GET /admin/logs redirects to login when not authenticated" do
    get admin_logs_path
    assert_redirected_to new_session_path
  end
end
