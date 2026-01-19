class CreateSyncLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :sync_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :log_type, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.text :message
      t.json :metadata

      t.timestamps
    end

    add_index :sync_logs, :log_type
    add_index :sync_logs, :status
    add_index :sync_logs, :created_at
  end
end
