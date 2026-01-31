class BackfillPersonalRecords < ActiveRecord::Migration[8.1]
  def up
    Workout
      .strength
      .where.not(ended_at: nil)
      .order(:started_at)
      .find_each do |workout|
        PersonalRecordDetector.new(workout: workout).call
      end
  end

  def down
    PersonalRecord.delete_all
  end
end
