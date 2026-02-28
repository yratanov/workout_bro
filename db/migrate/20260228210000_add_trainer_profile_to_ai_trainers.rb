class AddTrainerProfileToAiTrainers < ActiveRecord::Migration[8.1]
  def change
    add_column :ai_trainers, :trainer_profile, :text
  end
end
