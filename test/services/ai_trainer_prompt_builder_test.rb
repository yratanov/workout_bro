require "test_helper"

class AiTrainerPromptBuilderTest < ActiveSupport::TestCase
  setup do
    @ai_trainer = ai_trainers(:johns_trainer)
    @ai_trainer.update!(
      approach: :balanced,
      communication_style: :motivational,
      goal_general_fitness: true,
      goal_build_muscle: true,
      train_on_existing_data: false
    )
  end

  test "includes role instructions" do
    result = AiTrainerPromptBuilder.new(@ai_trainer).call
    assert_match(/personalized AI fitness trainer persona/, result)
  end

  test "includes personality section" do
    result = AiTrainerPromptBuilder.new(@ai_trainer).call
    assert_match(/Balanced/, result)
    assert_match(/Motivational/, result)
  end

  test "includes goals section" do
    result = AiTrainerPromptBuilder.new(@ai_trainer).call
    assert_match(/Build muscle/, result)
    assert_match(/General fitness/, result)
  end

  test "includes custom instructions when present" do
    @ai_trainer.update!(custom_instructions: "Focus on compound movements")
    result = AiTrainerPromptBuilder.new(@ai_trainer).call
    assert_match(/Focus on compound movements/, result)
  end

  test "does not include workout data" do
    @ai_trainer.update!(train_on_existing_data: true)
    result = AiTrainerPromptBuilder.new(@ai_trainer).call
    refute_match(/Workout History/, result)
  end
end
