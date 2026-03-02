class ChangeAiTrainerActivitiesFkToNullify < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :ai_trainer_activities, :ai_trainers
    add_foreign_key :ai_trainer_activities, :ai_trainers, on_delete: :nullify

    change_column_null :ai_trainer_activities, :ai_trainer_id, true
  end
end
