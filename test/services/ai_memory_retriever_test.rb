require "test_helper"

class AiMemoryRetrieverTest < ActiveSupport::TestCase
  setup do
    @user = users(:john)
    @user.update!(
      ai_provider: "gemini",
      ai_model: "gemini-2.0-flash",
      ai_api_key: "test-key"
    )
  end

  test "returns all memories when under limit" do
    AiClient.stubs(:for).returns(stub_client)

    result = AiMemoryRetriever.new(user: @user, prompt: "test").call
    assert_equal @user.ai_memories.count, result.length
    assert result.all? { |m| m.is_a?(AiMemory) }
  end

  test "returns empty array when user has no memories" do
    @user.ai_memories.destroy_all

    result = AiMemoryRetriever.new(user: @user, prompt: "test").call
    assert_equal [], result
  end

  test "ranks high importance memories higher" do
    @user.ai_memories.destroy_all
    # Create two memories with same age, no embeddings
    high =
      @user.ai_memories.create!(
        category: :health,
        content: "Bad knee",
        importance: 9
      )
    low =
      @user.ai_memories.create!(
        category: :behavior,
        content: "Likes morning",
        importance: 2
      )

    AiClient.stubs(:for).returns(stub_client)

    result = AiMemoryRetriever.new(user: @user, prompt: "test").call
    assert_equal high, result.first
    assert_equal low, result.last
  end

  test "ranks recent memories higher than old ones with same importance" do
    @user.ai_memories.destroy_all
    old =
      @user.ai_memories.create!(
        category: :progress,
        content: "Old progress",
        importance: 5,
        created_at: 1.year.ago
      )
    recent =
      @user.ai_memories.create!(
        category: :progress,
        content: "Recent progress",
        importance: 5,
        created_at: 1.hour.ago
      )

    AiClient.stubs(:for).returns(stub_client)

    result = AiMemoryRetriever.new(user: @user, prompt: "test").call
    assert_equal recent, result.first
    assert_equal old, result.last
  end

  test "caps memories per category at MAX_PER_CATEGORY" do
    @user.ai_memories.destroy_all
    7.times do |i|
      @user.ai_memories.create!(
        category: :progress,
        content: "Progress note #{i}",
        importance: 5
      )
    end

    AiClient.stubs(:for).returns(stub_client)

    result = AiMemoryRetriever.new(user: @user, prompt: "test").call
    assert_equal AiMemoryRetriever::MAX_PER_CATEGORY, result.length
  end

  test "respects overall LIMIT" do
    @user.ai_memories.destroy_all
    30.times do |i|
      cat = AiMemory.categories.keys[i % 7]
      @user.ai_memories.create!(
        category: cat,
        content: "Memory #{i}",
        importance: 5
      )
    end

    AiClient.stubs(:for).returns(stub_client)

    result = AiMemoryRetriever.new(user: @user, prompt: "test").call
    assert result.length <= AiMemoryRetriever::LIMIT
  end

  test "works with nil prompt" do
    AiClient.stubs(:for).returns(stub_client)

    result = AiMemoryRetriever.new(user: @user, prompt: nil).call
    assert result.length > 0
  end

  test "uses similarity when embeddings are present" do
    @user.ai_memories.destroy_all

    # Create a memory with embedding similar to the prompt embedding
    similar_embedding = Array.new(768) { |i| (Math.sin(i) * 0.1).round(6) }
    dissimilar_embedding =
      Array.new(768) { |i| (Math.cos(i + 100) * 0.1).round(6) }

    similar =
      @user.ai_memories.create!(
        category: :preferences,
        content: "Likes bench press",
        importance: 5,
        embedding: similar_embedding.to_json,
        created_at: 30.days.ago
      )
    dissimilar =
      @user.ai_memories.create!(
        category: :preferences,
        content: "Likes running",
        importance: 5,
        embedding: dissimilar_embedding.to_json,
        created_at: 1.day.ago
      )

    # Stub the client to return the similar embedding as the prompt embedding
    client = stub_client
    client.stubs(:generate_embedding).returns(similar_embedding)
    AiClient.stubs(:for).returns(client)

    result =
      AiMemoryRetriever.new(user: @user, prompt: "bench press workout").call
    assert_equal similar, result.first
  end

  test "gracefully handles embedding API failure" do
    client = stub_client
    client.stubs(:generate_embedding).raises(
      AiClients::Base::Error.new("API down")
    )
    AiClient.stubs(:for).returns(client)

    result = AiMemoryRetriever.new(user: @user, prompt: "test").call
    assert result.length > 0
  end

  private

  def stub_client
    client = Object.new
    client.define_singleton_method(:generate_embedding) { |_text| nil }
    client.define_singleton_method(:respond_to?) do |method, *|
      method == :generate_embedding || super(method)
    end
    client
  end
end
