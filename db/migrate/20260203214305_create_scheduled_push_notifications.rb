class CreateScheduledPushNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :scheduled_push_notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :job_id, null: false
      t.string :notification_type, null: false
      t.datetime :scheduled_for, null: false
      t.string :status, default: "pending", null: false

      t.timestamps
    end

    add_index :scheduled_push_notifications, :job_id, unique: true
  end
end
