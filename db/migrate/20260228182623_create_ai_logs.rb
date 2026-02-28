class CreateAiLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :action, null: false
      t.string :model
      t.text :prompt
      t.text :response
      t.text :error
      t.integer :duration_ms

      t.timestamps
    end

    add_index :ai_logs, :created_at
  end
end
