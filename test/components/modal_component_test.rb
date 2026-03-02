require "test_helper"

class ModalComponentTest < ActiveSupport::TestCase
  test "size_class returns max-w-sm for sm" do
    component = ModalComponent.new(size: "sm")
    assert_equal "max-w-sm", component.size_class
  end

  test "size_class returns max-w-lg for md" do
    component = ModalComponent.new(size: "md")
    assert_equal "max-w-lg", component.size_class
  end

  test "size_class returns max-w-2xl for lg" do
    component = ModalComponent.new(size: "lg")
    assert_equal "max-w-2xl", component.size_class
  end

  test "size_class returns max-w-4xl for xl" do
    component = ModalComponent.new(size: "xl")
    assert_equal "max-w-4xl", component.size_class
  end

  test "size_class returns max-w-lg for unknown size" do
    component = ModalComponent.new(size: "unknown")
    assert_equal "max-w-lg", component.size_class
  end

  test "open? returns false by default" do
    component = ModalComponent.new
    refute component.open?
  end

  test "open? returns true when open is set" do
    component = ModalComponent.new(open: true)
    assert component.open?
  end
end
