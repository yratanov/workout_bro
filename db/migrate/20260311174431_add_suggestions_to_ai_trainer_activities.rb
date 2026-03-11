class AddSuggestionsToAiTrainerActivities < ActiveRecord::Migration[8.1]
  def change
    add_column :ai_trainer_activities, :suggestions, :text
  end
end
