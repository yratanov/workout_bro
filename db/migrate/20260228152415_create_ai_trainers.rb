class CreateAiTrainers < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_trainers do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.integer :approach, default: 2, null: false
      t.integer :communication_style, default: 2, null: false
      t.string :custom_instructions
      t.boolean :goal_build_muscle, default: false, null: false
      t.boolean :goal_lose_weight, default: false, null: false
      t.boolean :goal_improve_endurance, default: false, null: false
      t.boolean :goal_increase_strength, default: false, null: false
      t.boolean :goal_general_fitness, default: true, null: false
      t.boolean :train_on_existing_data, default: true, null: false
      t.integer :status, default: 0, null: false
      t.json :error_details
      t.text :summary
      t.text :system_prompt

      t.timestamps
    end
  end
end
