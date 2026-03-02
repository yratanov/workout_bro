require "test_helper"

class AiRoutinePromptBuilderTest < ActiveSupport::TestCase
  setup do
    @user = users(:john)
    @params = {
      frequency: "4",
      split_type: "Upper/Lower",
      experience_level: "Intermediate",
      focus_areas: %w[chest back],
      additional_context: "No shoulder injuries"
    }
  end

  test "includes task instructions mentioning new exercises and supersets" do
    result = AiRoutinePromptBuilder.new(@user, @params).call
    assert_match(/workout routine/, result)
    assert_match(/new exercises/, result)
    assert_match(/supersets/, result)
  end

  test "includes user preferences" do
    result = AiRoutinePromptBuilder.new(@user, @params).call
    assert_match(/4 days per week/, result)
    assert_match(%r{Upper/Lower}, result)
    assert_match(/Intermediate/, result)
    assert_match(/chest, back/, result)
    assert_match(/No shoulder injuries/, result)
  end

  test "includes exercise list" do
    result = AiRoutinePromptBuilder.new(@user, @params).call
    assert_match(/Bench Press/, result)
    assert_match(/Squat/, result)
    assert_match(/Deadlift/, result)
  end

  test "includes superset list" do
    result = AiRoutinePromptBuilder.new(@user, @params).call
    assert_match(/Available Supersets/, result)
    assert_match(/Push Pull/, result)
    assert_match(/Arm Circuit/, result)
  end

  test "includes valid muscle group names" do
    result = AiRoutinePromptBuilder.new(@user, @params).call
    assert_match(/Valid Muscle Groups/, result)
    assert_match(/chest/, result)
    assert_match(/back/, result)
    assert_match(/legs/, result)
  end

  test "includes new JSON format with object exercises and superset examples" do
    result = AiRoutinePromptBuilder.new(@user, @params).call
    assert_match(/"name": "Exercise Name"/, result)
    assert_match(/"muscle": "chest"/, result)
    assert_match(/"superset": "Superset Name"/, result)
  end

  test "includes comment field in the JSON format example" do
    result = AiRoutinePromptBuilder.new(@user, @params).call
    assert_match(/"comment"/, result)
    assert_match(/concise/, result)
  end

  test "includes output format instructions" do
    result = AiRoutinePromptBuilder.new(@user, @params).call
    assert_match(/JSON/, result)
    assert_match(/4/, result)
  end

  test "omits focus areas when empty" do
    @params[:focus_areas] = []
    result = AiRoutinePromptBuilder.new(@user, @params).call
    refute_match(/Focus areas/, result)
  end

  test "omits additional context when blank" do
    @params[:additional_context] = ""
    result = AiRoutinePromptBuilder.new(@user, @params).call
    refute_match(/Additional context/, result)
  end

  test "omits superset section when user has no supersets" do
    user_without_supersets = users(:jane)
    result = AiRoutinePromptBuilder.new(user_without_supersets, @params).call
    refute_match(/Available Supersets/, result)
  end
end
