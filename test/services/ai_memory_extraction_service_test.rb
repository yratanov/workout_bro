require "test_helper"

class AiMemoryExtractionServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:john)
    @user.update!(
      ai_provider: "gemini",
      ai_model: "gemini-2.0-flash",
      ai_api_key: "test-key"
    )
  end

  test "extracts new memories from activity content" do
    VCR.use_cassette("ai_memory_extraction/success") do
      service =
        AiMemoryExtractionService.new(
          user: @user,
          activity_content: "Great workout session"
        )
      memories = service.call
      assert memories.is_a?(Array)
      assert memories.length > 0
      assert memories.all? { |m| m.is_a?(AiMemory) }
    end
  end

  test "returns empty array when AI responds NONE" do
    VCR.use_cassette("ai_memory_extraction/none") do
      service =
        AiMemoryExtractionService.new(
          user: @user,
          activity_content: "Basic workout"
        )
      memories = service.call
      assert_equal [], memories
    end
  end

  test "deduplicates against existing memories" do
    VCR.use_cassette("ai_memory_extraction/duplicate") do
      service =
        AiMemoryExtractionService.new(
          user: @user,
          activity_content: "Workout data"
        )
      initial_count = @user.ai_memories.count
      service.call
      assert_equal initial_count, @user.ai_memories.count
    end
  end

  test "handles replacement directive" do
    old_memory = ai_memories(:johns_schedule)
    assert_equal "Typically trains 3-4 times per week", old_memory.content

    VCR.use_cassette("ai_memory_extraction/replacement") do
      service =
        AiMemoryExtractionService.new(
          user: @user,
          activity_content: "Updated workout data"
        )
      memories = service.call
      assert memories.any? { |m| m.content.include?("4-5 times per week") }
    end

    assert_nil AiMemory.find_by(id: old_memory.id)
  end

  test "skips invalid categories" do
    VCR.use_cassette("ai_memory_extraction/invalid_category") do
      service =
        AiMemoryExtractionService.new(
          user: @user,
          activity_content: "Workout data"
        )
      initial_count = @user.ai_memories.count
      service.call
      assert_equal initial_count, @user.ai_memories.count
    end
  end
end
