class CreateAiTrainerMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_trainer_messages do |t|
      t.references :ai_trainer_activity, null: false, foreign_key: true
      t.integer :role, null: false
      t.text :content, null: false

      t.timestamps
    end
  end
end
