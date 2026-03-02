# frozen_string_literal: true

class DropWeeklyReports < ActiveRecord::Migration[8.1]
  def up
    drop_table :weekly_reports
  end

  def down
    create_table :weekly_reports do |t|
      t.integer :user_id, null: false
      t.date :week_start, null: false
      t.text :ai_summary
      t.integer :status, default: 0, null: false
      t.text :error_message
      t.datetime :viewed_at
      t.timestamps
    end

    add_index :weekly_reports, %i[user_id week_start], unique: true
    add_foreign_key :weekly_reports, :users
  end
end
