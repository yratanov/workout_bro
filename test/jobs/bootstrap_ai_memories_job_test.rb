require "test_helper"

class BootstrapAiMemoriesJobTest < ActiveJob::TestCase
  setup do
    @user = users(:john)
    @user.update!(
      ai_provider: "gemini",
      ai_model: "gemini-2.0-flash",
      ai_api_key: "test-key"
    )
  end

  test "extracts memories from workout history" do
    VCR.use_cassette("ai_memory_extraction/bootstrap") do
      assert_difference("AiMemory.count", 2) do
        BootstrapAiMemoriesJob.perform_now(user: @user)
      end
    end
  end

  test "skips when user has no AI configured" do
    @user.update_columns(ai_provider: nil, ai_model: nil, ai_api_key: nil)

    AiMemoryExtractionService.any_instance.expects(:call).never

    BootstrapAiMemoriesJob.perform_now(user: @user)
  end

  test "skips when user has no workout data" do
    @user.workouts.destroy_all

    AiMemoryExtractionService.any_instance.expects(:call).never

    BootstrapAiMemoriesJob.perform_now(user: @user)
  end

  test "rescues and logs errors" do
    AiMemoryExtractionService
      .any_instance
      .stubs(:call)
      .raises(StandardError, "API error")

    WorkoutExporter
      .any_instance
      .stubs(:call)
      .returns("date,exercise\n2026-01-01,Bench Press\n")

    assert_nothing_raised { BootstrapAiMemoriesJob.perform_now(user: @user) }
  end
end
