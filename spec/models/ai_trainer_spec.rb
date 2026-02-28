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
#  summary                :text
#  system_prompt          :text
#  train_on_existing_data :boolean          default(TRUE), not null
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
#  user_id  (user_id => users.id) ON DELETE => cascade
#
describe AiTrainer do
  fixtures :all

  let(:ai_trainer) { ai_trainers(:johns_trainer) }

  describe "enums" do
    it "defines approach enum" do
      expect(AiTrainer.approaches).to eq("supportive" => 0, "tough_love" => 1, "balanced" => 2)
    end

    it "defines communication_style enum" do
      expect(AiTrainer.communication_styles).to eq("concise" => 0, "detailed" => 1, "motivational" => 2)
    end

    it "defines status enum" do
      expect(AiTrainer.statuses).to eq("pending" => 0, "in_progress" => 1, "completed" => 2, "failed" => 3)
    end
  end

  describe "#processing?" do
    it "returns true when pending" do
      ai_trainer.status = :pending
      expect(ai_trainer.processing?).to be true
    end

    it "returns true when in_progress" do
      ai_trainer.status = :in_progress
      expect(ai_trainer.processing?).to be true
    end

    it "returns false when completed" do
      ai_trainer.status = :completed
      expect(ai_trainer.processing?).to be false
    end

    it "returns false when failed" do
      ai_trainer.status = :failed
      expect(ai_trainer.processing?).to be false
    end
  end

  describe "#configured?" do
    it "returns true when completed with summary" do
      ai_trainer.status = :completed
      ai_trainer.summary = "A trainer summary"
      expect(ai_trainer.configured?).to be true
    end

    it "returns false when not completed" do
      ai_trainer.status = :pending
      ai_trainer.summary = "A trainer summary"
      expect(ai_trainer.configured?).to be false
    end

    it "returns false when summary is blank" do
      ai_trainer.status = :completed
      ai_trainer.summary = nil
      expect(ai_trainer.configured?).to be false
    end
  end

  describe "#goals" do
    it "returns active goals" do
      ai_trainer.goal_general_fitness = true
      ai_trainer.goal_build_muscle = true
      ai_trainer.goal_lose_weight = false
      ai_trainer.goal_improve_endurance = false
      ai_trainer.goal_increase_strength = false

      expect(ai_trainer.goals).to contain_exactly(:goal_build_muscle, :goal_general_fitness)
    end

    it "returns empty array when no goals are set" do
      AiTrainer::GOALS.each { |g| ai_trainer.send(:"#{g}=", false) }
      expect(ai_trainer.goals).to be_empty
    end
  end
end
