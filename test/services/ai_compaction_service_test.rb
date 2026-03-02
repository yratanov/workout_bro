require "test_helper"

class AiCompactionServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:john)
    @user.update!(
      ai_provider: "gemini",
      ai_model: "gemini-2.0-flash",
      ai_api_key: "test-key"
    )
    @ai_trainer = @user.ai_trainer
    @ai_trainer.update!(
      status: :completed,
      trainer_profile: "A balanced fitness trainer."
    )
  end

  test "calls generate_chat with conversation messages and returns result" do
    mock_client = mock("AiClient")
    AiClient.stubs(:for).returns(mock_client)
    mock_client
      .expects(:generate_chat)
      .with do |messages, **opts|
        messages.is_a?(Array) &&
          opts[:system_instruction].include?("A balanced fitness trainer.") &&
          messages.last[:role] == "user" &&
          messages.last[:text].include?("updated comprehensive training review")
      end
      .returns("Compacted review")

    result = AiCompactionService.new(@ai_trainer).call
    assert_equal "Compacted review", result
  end

  test "includes trainer context in system_instruction" do
    mock_client = mock("AiClient")
    AiClient.stubs(:for).returns(mock_client)
    mock_client
      .expects(:generate_chat)
      .with do |_messages, **opts|
        opts[:system_instruction].include?("A balanced fitness trainer.")
      end
      .returns("Review")

    AiCompactionService.new(@ai_trainer).call
  end
end
