class CreateErrorLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :error_logs do |t|
      t.string :error_class, null: false
      t.text :message
      t.integer :severity, null: false, default: 0
      t.string :source, default: "application"
      t.json :backtrace
      t.json :context
      t.string :request_id

      t.timestamps
    end

    add_index :error_logs, :created_at
    add_index :error_logs, :severity
  end
end
