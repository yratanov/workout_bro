require "test_helper"

class Admin::AiLogsHelperTest < ActionView::TestCase
  include Admin::AiLogsHelper

  test "formats valid JSON with pretty print" do
    json = '[{"system_instruction":"Be helpful"},{"role":"user","text":"Hello"}]'
    result = format_ai_log_text(json)

    assert_includes result, "\"system_instruction\": \"Be helpful\""
    assert_includes result, "\n"
  end

  test "returns plain text as-is when not valid JSON" do
    plain = "Generate a workout plan for the user"
    assert_equal plain, format_ai_log_text(plain)
  end
end
