class CreateWeeklyReports < ActiveRecord::Migration[8.1]
  def change
    create_table :weekly_reports do |t|
      t.references :user, null: false, foreign_key: true
      t.date :week_start, null: false
      t.text :ai_summary
      t.integer :status, default: 0, null: false
      t.text :error_message

      t.timestamps
    end

    add_index :weekly_reports, %i[user_id week_start], unique: true
  end
end
