require "test_helper"

class MusclesSeederTest < ActiveSupport::TestCase
  test "skips all existing muscles from fixtures" do
    result = MusclesSeeder.new.call

    assert_equal 8, result[:skipped]
    assert_equal 0, result[:created]
  end

  test "returns a hash with created and skipped counts" do
    result = MusclesSeeder.new.call

    assert_instance_of Hash, result
    assert result.key?(:created)
    assert result.key?(:skipped)
  end

  test "creates new muscles when they do not exist" do
    new_muscles =
      MusclesSeeder::MUSCLES.map do |name|
        m = Muscle.new(name: name)
        m.stubs(:save!)
        m
      end

    # Mocha .returns with multiple values returns them in succession
    Muscle.stubs(:find_or_initialize_by).returns(*new_muscles)

    result = MusclesSeeder.new.call

    assert_equal 8, result[:created]
    assert_equal 0, result[:skipped]
  end
end
