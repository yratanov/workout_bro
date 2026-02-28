class CreateAiTrainerActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_trainer_activities do |t|
      t.references :user, null: false, foreign_key: true
      t.references :ai_trainer, null: false, foreign_key: { on_delete: :cascade }
      t.references :workout, null: true, foreign_key: { on_delete: :nullify }
      t.integer :activity_type, null: false
      t.text :content
      t.integer :status, default: 0, null: false
      t.text :error_message
      t.date :week_start
      t.datetime :viewed_at
      t.timestamps
    end

    add_index :ai_trainer_activities, %i[user_id activity_type]
    add_index :ai_trainer_activities, %i[user_id created_at]
    add_index :ai_trainer_activities,
              %i[ai_trainer_id activity_type created_at],
              name: "idx_activities_trainer_type_created"
  end
end
