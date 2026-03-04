require "test_helper"

class AiClients::FakeTest < ActiveSupport::TestCase
  setup do
    @client = AiClients::Fake.new
    @user = users(:john)
  end

  test "generate returns fake response" do
    result = @client.generate("test prompt")
    assert_kind_of String, result
    assert result.present?
  end

  test "generate returns workout feedback for workout_feedback action" do
    result =
      @client.generate(
        "test",
        log_context: {
          user: @user,
          action: "workout_feedback"
        }
      )
    assert_includes result, "Solid session"
  end

  test "generate returns NONE for memory extraction" do
    result =
      @client.generate(
        "test",
        log_context: {
          user: @user,
          action: "memory_extraction"
        }
      )
    assert_equal "NONE", result
  end

  test "generate returns JSON for routine suggestion" do
    result =
      @client.generate(
        "test",
        log_context: {
          user: @user,
          action: "routine_suggestion"
        }
      )
    parsed = JSON.parse(result)
    assert parsed["name"].present?
    assert parsed["days"].is_a?(Array)
  end

  test "generate_chat returns fake response" do
    messages = [{ role: "user", text: "Hello" }]
    result = @client.generate_chat(messages)
    assert_kind_of String, result
    assert result.present?
  end

  test "generate_chat_stream yields accumulated text" do
    messages = [{ role: "user", text: "Hello" }]
    chunks = []
    result =
      @client.generate_chat_stream(messages) do |accumulated|
        chunks << accumulated
      end
    assert_kind_of String, result
    assert chunks.any?
    assert_equal result, chunks.last
  end

  test "generate logs request when log_context provided" do
    assert_difference "AiLog.count", 1 do
      @client.generate(
        "test",
        log_context: {
          user: @user,
          action: "workout_feedback"
        }
      )
    end

    log = AiLog.last
    assert_equal "fake", log.model
    assert_equal "workout_feedback", log.action
  end

  test "generate does not log when no log_context" do
    assert_no_difference "AiLog.count" do
      @client.generate("test")
    end
  end
end
