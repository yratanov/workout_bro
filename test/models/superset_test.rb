require "test_helper"

# == Schema Information
#
# Table name: supersets
# Database name: primary
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_supersets_on_user_id  (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#

class SupersetTest < ActiveSupport::TestCase
  test "requires a name" do
    superset = Superset.new(user: users(:john))
    assert_not superset.valid?
    assert_includes superset.errors[:name], "can't be blank"
  end

  test "requires a user" do
    superset = Superset.new(name: "Test Superset")
    assert_not superset.valid?
    assert_includes superset.errors[:user], "must exist"
  end

  test "is valid with name and user" do
    superset = Superset.new(name: "Test Superset", user: users(:john))
    assert superset.valid?
  end

  test "has many superset_exercises" do
    superset = supersets(:push_pull)
    assert_equal 2, superset.superset_exercises.count
  end

  test "has many exercises through superset_exercises" do
    superset = supersets(:push_pull)
    assert_includes superset.exercises, exercises(:bench_press)
    assert_includes superset.exercises, exercises(:pull_up)
  end

  test "orders superset_exercises by position" do
    superset = supersets(:push_pull)
    positions = superset.superset_exercises.pluck(:position)
    assert_equal positions.sort, positions
  end

  test "display_name returns the superset name" do
    superset = supersets(:push_pull)
    assert_equal "Push Pull", superset.display_name
  end

  test "destroys superset_exercises when superset is destroyed" do
    superset = supersets(:push_pull)
    superset_exercise_ids = superset.superset_exercises.pluck(:id)

    superset.destroy

    superset_exercise_ids.each do |id|
      assert_nil SupersetExercise.find_by(id: id)
    end
  end
end
