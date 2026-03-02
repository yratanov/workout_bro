class AddTokensToAiLogs < ActiveRecord::Migration[8.1]
  def change
    add_column :ai_logs, :input_tokens, :integer
    add_column :ai_logs, :output_tokens, :integer
    add_column :ai_logs, :total_tokens, :integer
  end
end
