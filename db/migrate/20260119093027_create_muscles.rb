class CreateMuscles < ActiveRecord::Migration[8.0]
  def change
    create_table :muscles do |t|
      t.string :name, null: false

      t.timestamps
    end
    add_index :muscles, :name, unique: true
  end
end
