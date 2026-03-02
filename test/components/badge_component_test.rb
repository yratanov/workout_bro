require "test_helper"

class BadgeComponentTest < ActiveSupport::TestCase
  test "size_class returns correct classes for sm" do
    component = BadgeComponent.new(size: "sm")
    assert_equal "text-xs px-2 py-1", component.size_class
  end

  test "size_class returns correct classes for md" do
    component = BadgeComponent.new(size: "md")
    assert_equal "text-sm px-3 py-1", component.size_class
  end

  test "size_class returns correct classes for lg" do
    component = BadgeComponent.new(size: "lg")
    assert_equal "text-base px-4 py-2", component.size_class
  end

  test "size_class returns default classes for unknown size" do
    component = BadgeComponent.new(size: "unknown")
    assert_equal "text-sm px-2 py-2", component.size_class
  end
end
