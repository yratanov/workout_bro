class CreateWorkouts < ActiveRecord::Migration[8.0]
  def change
    create_table :workouts do |t|
      t.date :date
      t.datetime :started_at
      t.datetime :ended_at

      t.timestamps
    end
  end
end
