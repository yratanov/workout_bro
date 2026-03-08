# frozen_string_literal: true

# == Schema Information
#
# Table name: ai_memories
# Database name: primary
#
#  id            :integer          not null, primary key
#  category      :integer          not null
#  content       :text             not null
#  embedding     :text
#  importance    :integer          default(5), not null
#  source        :string           default("auto"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  ai_trainer_id :integer
#  user_id       :integer          not null
#
# Indexes
#
#  index_ai_memories_on_ai_trainer_id         (ai_trainer_id)
#  index_ai_memories_on_user_id_and_category  (user_id,category)
#
# Foreign Keys
#
#  ai_trainer_id  (ai_trainer_id => ai_trainers.id)
#  user_id        (user_id => users.id)
#
class AiMemory < ApplicationRecord
  belongs_to :user
  belongs_to :ai_trainer, optional: true

  enum :category,
       {
         schedule: 0,
         equipment: 1,
         health: 2,
         preferences: 3,
         progress: 4,
         behavior: 5,
         goals: 6
       }

  CATEGORY_IMPORTANCE = {
    "health" => 9,
    "goals" => 8,
    "equipment" => 7,
    "schedule" => 6,
    "preferences" => 5,
    "progress" => 4,
    "behavior" => 3
  }.freeze

  validates :content, presence: true, length: { maximum: 500 }
  validates :category, presence: true
  validates :importance, numericality: { only_integer: true, in: 1..10 }

  scope :for_prompt, -> { order(category: :asc, created_at: :desc) }

  def default_importance
    CATEGORY_IMPORTANCE.fetch(category, 5)
  end

  def embedding_vector
    return nil if embedding.blank?

    JSON.parse(embedding)
  end

  def embedding_vector=(vector)
    self.embedding = vector&.to_json
  end
end
