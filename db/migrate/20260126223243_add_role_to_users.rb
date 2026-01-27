class AddRoleToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :role, :integer, default: 0, null: false

    reversible do |dir|
      dir.up do
        first_user_id = execute("SELECT id FROM users ORDER BY id LIMIT 1").first&.fetch("id")
        if first_user_id
          execute("UPDATE users SET role = 1 WHERE id = #{first_user_id}")
        end
      end
    end
  end
end
