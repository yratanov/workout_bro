class CreateInvites < ActiveRecord::Migration[8.0]
  def change
    create_table :invites do |t|
      t.string :token, null: false
      t.references :user, null: false, foreign_key: true
      t.references :used_by_user, null: true, foreign_key: { to_table: :users }
      t.datetime :used_at

      t.timestamps
    end
    add_index :invites, :token, unique: true
  end
end
