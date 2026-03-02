class RemoveDeadColumnsFromAiTrainers < ActiveRecord::Migration[8.1]
  def change
    remove_column :ai_trainers, :system_prompt, :text
    remove_column :ai_trainers, :summary, :text
  end
end
