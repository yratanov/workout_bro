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
    VCR.use_cassette("ai_compaction/chat") do
      result = AiCompactionService.new(@ai_trainer).call
      assert_equal "Compacted review", result
    end
  end
end
