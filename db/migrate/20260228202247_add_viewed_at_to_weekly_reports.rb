class AddViewedAtToWeeklyReports < ActiveRecord::Migration[8.1]
  def change
    add_column :weekly_reports, :viewed_at, :datetime
  end
end
