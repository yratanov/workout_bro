class MarkExistingUsersSetupCompleted < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL
      UPDATE users SET setup_completed = true WHERE setup_completed = false
    SQL
  end

  def down
    # No-op: we don't want to mark users as incomplete on rollback
  end
end
