require "test_helper"

class ExercisesImporterTest < ActiveSupport::TestCase
  test "accepts user" do
    importer = ExercisesImporter.new(user: users(:john))
    assert_instance_of ExercisesImporter, importer
  end

  test "uses locale from user" do
    user = users(:john)
    user.update!(locale: "ru")
    importer = ExercisesImporter.new(user: user)
    assert_instance_of ExercisesImporter, importer
  end

  test "imports exercises from CSV" do
    user = users(:john)
    with_stubbed_csv(user, sample_csv_content) do
      assert_difference "Exercise.count", 2 do
        ExercisesImporter.new(user: user).call
      end
    end
  end

  test "returns import statistics" do
    user = users(:john)
    with_stubbed_csv(user, sample_csv_content) do
      result = ExercisesImporter.new(user: user).call
      assert_equal({ imported: 2, skipped: 0 }, result)
    end
  end

  test "creates exercises with correct attributes" do
    user = users(:john)
    with_stubbed_csv(user, sample_csv_content) do
      ExercisesImporter.new(user: user).call

      exercise = Exercise.find_by(name: "Test Exercise")
      assert_equal user, exercise.user
      assert exercise.with_weights
      refute exercise.with_band
      assert_equal "chest", exercise.muscle.name
    end
  end

  test "creates band exercises correctly" do
    user = users(:john)
    with_stubbed_csv(user, sample_csv_content) do
      ExercisesImporter.new(user: user).call

      exercise = Exercise.find_by(name: "Band Exercise")
      assert_equal user, exercise.user
      refute exercise.with_weights
      assert exercise.with_band
    end
  end

  test "skips existing exercises" do
    user = users(:john)
    user.exercises.create!(
      name: "Test Exercise",
      with_weights: true,
      with_band: false
    )

    with_stubbed_csv(user, sample_csv_content) do
      assert_difference "Exercise.count", 1 do
        ExercisesImporter.new(user: user).call
      end
    end
  end

  test "returns correct statistics when exercise already exists" do
    user = users(:john)
    user.exercises.create!(
      name: "Test Exercise",
      with_weights: true,
      with_band: false
    )

    with_stubbed_csv(user, sample_csv_content) do
      result = ExercisesImporter.new(user: user).call
      assert_equal({ imported: 1, skipped: 1 }, result)
    end
  end

  test "creates exercise with nil muscle when muscle does not exist" do
    user = users(:john)
    csv = <<~CSV
      name,muscles,with_weights,with_band
      Unknown Muscle Exercise,nonexistent,true,false
    CSV

    with_stubbed_csv(user, csv) do
      ExercisesImporter.new(user: user).call
      exercise = Exercise.find_by(name: "Unknown Muscle Exercise")
      assert_nil exercise.muscle
    end
  end

  test "returns zero imports with empty CSV" do
    user = users(:john)
    csv = <<~CSV
      name,muscles,with_weights,with_band
    CSV

    with_stubbed_csv(user, csv) do
      result = ExercisesImporter.new(user: user).call
      assert_equal({ imported: 0, skipped: 0 }, result)
    end
  end

  test "falls back to default CSV when locale-specific file does not exist" do
    user = users(:john)
    user.update!(locale: "ru")
    importer = ExercisesImporter.new(user: user)
    path = importer.send(:path_for_locale, "ru")
    assert_match(/exercises/, path.to_s)
  end

  test "defaults to English when user locale is nil" do
    user = users(:john)
    user.update!(locale: nil)
    importer = ExercisesImporter.new(user: user)
    assert_match(/exercises/, importer.send(:path_for_locale, "en").to_s)
  end

  private

  def sample_csv_content
    <<~CSV
      name,muscles,with_weights,with_band
      Test Exercise,chest,true,false
      Band Exercise,legs,false,true
    CSV
  end

  def with_stubbed_csv(user, csv_content)
    temp_file = Tempfile.new(%w[exercises .csv])
    temp_file.write(csv_content)
    temp_file.rewind

    ExercisesImporter
      .any_instance
      .stubs(:path_for_locale)
      .returns(temp_file.path)
    yield
  ensure
    temp_file.close
    temp_file.unlink
  end
end
