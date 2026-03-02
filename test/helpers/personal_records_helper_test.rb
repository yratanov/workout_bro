require "test_helper"

class PersonalRecordsHelperTest < ActionView::TestCase
  test "pr_type_badge_class returns yellow classes for max_weight" do
    assert_equal "bg-yellow-600/20 text-yellow-400",
                 pr_type_badge_class("max_weight")
  end

  test "pr_type_badge_class returns green classes for max_volume" do
    assert_equal "bg-green-600/20 text-green-400",
                 pr_type_badge_class("max_volume")
  end

  test "pr_type_badge_class returns blue classes for max_reps" do
    assert_equal "bg-blue-600/20 text-blue-400", pr_type_badge_class("max_reps")
  end

  test "pr_type_badge_class returns slate classes for unknown types" do
    assert_equal "bg-slate-600/20 text-slate-400",
                 pr_type_badge_class("unknown")
  end

  test "pr_type_badge_class handles symbol input" do
    assert_equal "bg-yellow-600/20 text-yellow-400",
                 pr_type_badge_class(:max_weight)
  end
end
