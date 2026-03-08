class AddScoringToAiMemories < ActiveRecord::Migration[8.1]
  def change
    add_column :ai_memories, :importance, :integer, null: false, default: 5
    add_column :ai_memories, :embedding, :text
  end
end
