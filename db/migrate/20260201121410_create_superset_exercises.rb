class CreateSupersetExercises < ActiveRecord::Migration[8.1]
  def change
    create_table :superset_exercises do |t|
      t.references :superset, null: false, foreign_key: { on_delete: :cascade }
      t.references :exercise, null: false, foreign_key: true
      t.integer :position, null: false

      t.timestamps
    end
    add_index :superset_exercises, [:superset_id, :position]
  end
end
