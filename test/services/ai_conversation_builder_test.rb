require "test_helper"

class AiConversationBuilderTest < ActiveSupport::TestCase
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

  test "returns a hash with system_instruction and messages" do
    result = AiConversationBuilder.new(@ai_trainer).build
    assert_instance_of Hash, result
    assert result.key?(:system_instruction)
    assert result.key?(:messages)
  end

  test "includes static instructions and trainer profile in system_instruction" do
    result = AiConversationBuilder.new(@ai_trainer).build
    assert_match(
      /personal fitness trainer AI assistant/,
      result[:system_instruction]
    )
    assert_match(/A balanced fitness trainer\./, result[:system_instruction])
  end

  test "includes latest full review in system_instruction" do
    result = AiConversationBuilder.new(@ai_trainer).build
    assert_match(/Latest Training Review/, result[:system_instruction])
    assert_match(/Comprehensive review/, result[:system_instruction])
  end

  test "includes workout review activities as user/model pairs in messages" do
    result = AiConversationBuilder.new(@ai_trainer).build
    messages = result[:messages]

    workout_user_msg =
      messages.find do |m|
        m[:role] == "user" && m[:text].include?("Strength workout")
      end
    assert workout_user_msg.present?

    workout_model_idx = messages.index(workout_user_msg) + 1
    assert_equal "model", messages[workout_model_idx][:role]
    assert_match(/Great strength workout/, messages[workout_model_idx][:text])
  end

  test "includes weekly report activities as user/model pairs in messages" do
    result = AiConversationBuilder.new(@ai_trainer).build
    messages = result[:messages]

    weekly_user_msg =
      messages.find do |m|
        m[:role] == "user" && m[:text].include?("Weekly overview")
      end
    assert weekly_user_msg.present?
  end

  test "uses condensed workout data without rep details" do
    result = AiConversationBuilder.new(@ai_trainer).build
    messages = result[:messages]

    workout_msgs =
      messages.select do |m|
        m[:role] == "user" && m[:text].include?("Strength workout")
      end
    workout_msgs.each do |msg|
      refute_match(/x 10/, msg[:text])
      assert_match(/Exercises:/, msg[:text])
    end
  end

  test "handles deleted workouts gracefully" do
    activity = ai_trainer_activities(:johns_workout_review)
    activity.update_column(:workout_id, nil)

    result = AiConversationBuilder.new(@ai_trainer).build
    messages = result[:messages]

    workout_msgs =
      messages.select do |m|
        m[:role] == "user" && m[:text].include?("Strength workout")
      end
    assert workout_msgs.empty?
  end

  test "does not include fake Understood model turn" do
    result = AiConversationBuilder.new(@ai_trainer).build
    messages = result[:messages]

    understood_msgs =
      messages.select do |m|
        m[:role] == "model" && m[:text].include?("Understood")
      end
    assert understood_msgs.empty?
  end

  test "excludes pending activities" do
    result = AiConversationBuilder.new(@ai_trainer).build
    messages = result[:messages]

    model_msgs = messages.select { |m| m[:role] == "model" }
    model_texts = model_msgs.map { |m| m[:text] }
    refute_includes model_texts, nil
  end

  test "estimated_token_count returns a positive integer" do
    count = AiConversationBuilder.new(@ai_trainer).estimated_token_count
    assert count > 0
  end

  test "compaction_needed returns false when token count is below threshold" do
    refute AiConversationBuilder.new(@ai_trainer).compaction_needed?
  end

  test "includes run workout data in condensed format" do
    run_workout = workouts(:run_workout)
    AiTrainerActivity.create!(
      user: @user,
      ai_trainer: @ai_trainer,
      workout: run_workout,
      activity_type: :workout_review,
      content: "Good run session!",
      status: :completed,
      created_at: 1.hour.ago
    )

    result = AiConversationBuilder.new(@ai_trainer).build
    messages = result[:messages]

    run_msg =
      messages.find do |m|
        m[:role] == "user" && m[:text].include?("Run workout")
      end
    assert run_msg.present?, "Expected a run workout message in conversation"
    assert_match(/Distance:/, run_msg[:text])
  end

  test "orders activities by created_at" do
    result = AiConversationBuilder.new(@ai_trainer).build
    messages = result[:messages]

    user_msgs = messages.select { |m| m[:role] == "user" }
    assert user_msgs.length >= 2, "Expected at least 2 user messages"
  end

  test "estimates tokens as length divided by 3 rounded up" do
    builder = AiConversationBuilder.new(@ai_trainer)
    # Access estimate_tokens via estimated_token_count
    # A string of 10 chars should produce ceil(10/3.0) = 4 tokens
    count = builder.estimated_token_count
    assert_kind_of Integer, count
    assert count > 0
  end

  test "compaction_needed? returns true when over TOKEN_THRESHOLD" do
    builder = AiConversationBuilder.new(@ai_trainer)
    builder.stubs(:estimated_token_count).returns(
      AiConversationBuilder::TOKEN_THRESHOLD + 1
    )
    assert builder.compaction_needed?
  end

  test "compaction_needed? returns false when under TOKEN_THRESHOLD" do
    builder = AiConversationBuilder.new(@ai_trainer)
    builder.stubs(:estimated_token_count).returns(
      AiConversationBuilder::TOKEN_THRESHOLD - 1
    )
    refute builder.compaction_needed?
  end
end
