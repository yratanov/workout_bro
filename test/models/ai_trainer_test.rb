require "test_helper"

# == Schema Information
#
# Table name: ai_trainers
# Database name: primary
#
#  id                     :integer          not null, primary key
#  approach               :integer          default("balanced"), not null
#  communication_style    :integer          default("motivational"), not null
#  custom_instructions    :string
#  error_details          :json
#  goal_build_muscle      :boolean          default(FALSE), not null
#  goal_general_fitness   :boolean          default(TRUE), not null
#  goal_improve_endurance :boolean          default(FALSE), not null
#  goal_increase_strength :boolean          default(FALSE), not null
#  goal_lose_weight       :boolean          default(FALSE), not null
#  status                 :integer          default("pending"), not null
#  train_on_existing_data :boolean          default(TRUE), not null
#  trainer_profile        :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  user_id                :integer          not null
#
# Indexes
#
#  index_ai_trainers_on_user_id  (user_id) UNIQUE
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#

class AiTrainerTest < ActiveSupport::TestCase
  test "defines approach enum" do
    assert_equal(
      { "supportive" => 0, "tough_love" => 1, "balanced" => 2 },
      AiTrainer.approaches
    )
  end

  test "defines communication_style enum" do
    assert_equal(
      { "concise" => 0, "detailed" => 1, "motivational" => 2 },
      AiTrainer.communication_styles
    )
  end

  test "defines status enum" do
    assert_equal(
      { "pending" => 0, "in_progress" => 1, "completed" => 2, "failed" => 3 },
      AiTrainer.statuses
    )
  end

  test "processing? returns true when pending" do
    trainer = ai_trainers(:johns_trainer)
    trainer.status = :pending
    assert trainer.processing?
  end

  test "processing? returns true when in_progress" do
    trainer = ai_trainers(:johns_trainer)
    trainer.status = :in_progress
    assert trainer.processing?
  end

  test "processing? returns false when completed" do
    trainer = ai_trainers(:johns_trainer)
    trainer.status = :completed
    refute trainer.processing?
  end

  test "processing? returns false when failed" do
    trainer = ai_trainers(:johns_trainer)
    trainer.status = :failed
    refute trainer.processing?
  end

  test "configured? returns true when completed with trainer_profile" do
    trainer = ai_trainers(:johns_trainer)
    trainer.status = :completed
    trainer.trainer_profile = "A trainer profile"
    assert trainer.configured?
  end

  test "configured? returns false when not completed" do
    trainer = ai_trainers(:johns_trainer)
    trainer.status = :pending
    trainer.trainer_profile = "A trainer profile"
    refute trainer.configured?
  end

  test "configured? returns false when trainer_profile is blank" do
    trainer = ai_trainers(:johns_trainer)
    trainer.status = :completed
    trainer.trainer_profile = nil
    refute trainer.configured?
  end

  test "goals returns active goals" do
    trainer = ai_trainers(:johns_trainer)
    trainer.goal_general_fitness = true
    trainer.goal_build_muscle = true
    trainer.goal_lose_weight = false
    trainer.goal_improve_endurance = false
    trainer.goal_increase_strength = false

    assert_equal %i[goal_build_muscle goal_general_fitness].sort,
                 trainer.goals.sort
  end

  test "goals returns empty array when no goals are set" do
    trainer = ai_trainers(:johns_trainer)
    AiTrainer::GOALS.each { |g| trainer.send(:"#{g}=", false) }
    assert_empty trainer.goals
  end
end
