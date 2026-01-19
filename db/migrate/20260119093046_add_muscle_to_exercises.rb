class AddMuscleToExercises < ActiveRecord::Migration[8.0]
  def up
    add_reference :exercises, :muscle, foreign_key: true

    # Migrate data: create muscles and link exercises
    execute <<-SQL.squish
      INSERT OR IGNORE INTO muscles (name, created_at, updated_at)
      SELECT DISTINCT LOWER(muscles), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM exercises
      WHERE muscles IS NOT NULL AND muscles != ''
    SQL

    execute <<-SQL.squish
      UPDATE exercises
      SET muscle_id = (SELECT id FROM muscles WHERE muscles.name = LOWER(exercises.muscles))
      WHERE muscles IS NOT NULL AND muscles != ''
    SQL

    remove_column :exercises, :muscles
  end

  def down
    add_column :exercises, :muscles, :string

    execute <<-SQL.squish
      UPDATE exercises
      SET muscles = (SELECT name FROM muscles WHERE muscles.id = exercises.muscle_id)
      WHERE muscle_id IS NOT NULL
    SQL

    remove_reference :exercises, :muscle
  end
end
