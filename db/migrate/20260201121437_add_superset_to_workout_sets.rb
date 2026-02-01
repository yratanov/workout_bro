class AddSupersetToWorkoutSets < ActiveRecord::Migration[8.1]
  def change
    add_reference :workout_sets, :superset, foreign_key: true
    add_column :workout_sets, :superset_group, :integer
    add_index :workout_sets, [:workout_id, :superset_group]
  end
end
