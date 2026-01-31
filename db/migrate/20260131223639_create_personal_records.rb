class CreatePersonalRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :personal_records do |t|
      t.references :user, null: false, foreign_key: true
      t.references :exercise, null: false, foreign_key: { on_delete: :cascade }
      t.references :workout_rep, null: false, foreign_key: { on_delete: :cascade }
      t.references :workout, null: false, foreign_key: { on_delete: :cascade }
      t.integer :pr_type, null: false, default: 0
      t.float :weight
      t.integer :reps, null: false
      t.float :volume
      t.string :band
      t.date :achieved_on, null: false

      t.timestamps
    end

    add_index :personal_records, %i[user_id exercise_id pr_type band], name: "index_prs_on_user_exercise_type_band"
  end
end
