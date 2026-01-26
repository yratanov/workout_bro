class AddUserIdToExercises < ActiveRecord::Migration[8.0]
  def change
    add_reference :exercises, :user, null: true, foreign_key: true

    reversible do |dir|
      dir.up do
        first_user_id = execute("SELECT id FROM users ORDER BY id LIMIT 1").first&.fetch("id")
        if first_user_id
          execute("UPDATE exercises SET user_id = #{first_user_id}")
        end
      end
    end

    change_column_null :exercises, :user_id, false
  end
end
