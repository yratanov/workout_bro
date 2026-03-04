class CreateAiMemories < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_memories do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.references :ai_trainer, null: true, foreign_key: true
      t.integer :category, null: false
      t.text :content, null: false
      t.string :source, null: false, default: "auto"
      t.timestamps
    end

    add_index :ai_memories, %i[user_id category]
  end
end
