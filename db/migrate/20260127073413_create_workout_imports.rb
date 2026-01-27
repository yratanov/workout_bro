class CreateWorkoutImports < ActiveRecord::Migration[8.0]
  def change
    create_table :workout_imports do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.integer :imported_count, null: false, default: 0
      t.integer :skipped_count, null: false, default: 0
      t.json :error_details
      t.string :original_filename

      t.timestamps
    end
  end
end
