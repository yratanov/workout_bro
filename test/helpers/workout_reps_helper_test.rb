require "test_helper"

class WorkoutRepsHelperTest < ActionView::TestCase
  test "weight_options generates options based on user weight settings" do
    user = users(:john)
    user.weight_min = 5
    user.weight_max = 15
    user.weight_step = 5
    user.weight_unit = "kg"

    options = weight_options(user)

    assert_equal [["5.0kg", 5.0], ["10.0kg", 10.0], ["15.0kg", 15.0]], options
  end

  test "weight_options uses the correct weight unit" do
    user = users(:john)
    user.weight_min = 10
    user.weight_max = 20
    user.weight_step = 5
    user.weight_unit = "lbs"

    options = weight_options(user)

    assert_equal [["10.0lbs", 10.0], ["15.0lbs", 15.0], ["20.0lbs", 20.0]],
                 options
  end

  test "weight_options starts from zero when weight_min is 0" do
    user = users(:john)
    user.weight_min = 0
    user.weight_max = 10
    user.weight_step = 5
    user.weight_unit = "kg"

    options = weight_options(user)

    assert_equal [["0.0kg", 0.0], ["5.0kg", 5.0], ["10.0kg", 10.0]], options
  end

  test "weight_options handles decimal steps" do
    user = users(:john)
    user.weight_min = 2.5
    user.weight_max = 7.5
    user.weight_step = 2.5
    user.weight_unit = "kg"

    options = weight_options(user)

    assert_equal [["2.5kg", 2.5], ["5.0kg", 5.0], ["7.5kg", 7.5]], options
  end
end
