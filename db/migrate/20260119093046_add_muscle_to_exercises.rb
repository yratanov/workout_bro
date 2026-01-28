class AddMuscleToExercises < ActiveRecord::Migration[8.0]
  # Mapping from old muscle names to standardized names
  MUSCLE_MAPPING = {
    "Back" => "back",
    "Chest" => "chest",
    "Shoulders" => "shoulders",
    "Biceps" => "biceps",
    "Triceps" => "triceps",
    "Traps" => "back",
    "Quads" => "legs",
    "Hamstrings" => "legs",
    "Glutes" => "glutes",
    "Calves" => "legs",
    "Core" => "core",
    "ABS" => "core",
    "Back, biceps" => "back",
    "Side delts" => "shoulders"
  }.freeze

  STANDARD_MUSCLES = %w[
    chest
    back
    shoulders
    biceps
    triceps
    legs
    glutes
    core
  ].freeze

  def up
    add_reference :exercises, :muscle, foreign_key: true

    # Create only the standardized muscles
    STANDARD_MUSCLES.each { |name| execute <<-SQL.squish }
        INSERT OR IGNORE INTO muscles (name, created_at, updated_at)
        VALUES ('#{name}', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
      SQL

    # Map old muscle names to standardized muscles
    MUSCLE_MAPPING.each { |old_name, new_name| execute <<-SQL.squish }
        UPDATE exercises
        SET muscle_id = (SELECT id FROM muscles WHERE muscles.name = '#{new_name}')
        WHERE muscles = '#{old_name}'
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
