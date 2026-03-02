require "test_helper"

class FormHelpersTest < ActionView::TestCase
  include FormHelpers

  test "input_class returns base classes" do
    result = input_class({})
    assert_includes result, "block"
    assert_includes result, "rounded-lg"
    assert_includes result, "border"
    assert_includes result, "bg-slate-800"
    assert_includes result, "w-full"
    assert_includes result, "border-slate-600"
  end

  test "input_class includes disabled classes when disabled is true" do
    result = input_class(disabled: true)
    assert_includes result, "bg-slate-900"
    assert_includes result, "cursor-not-allowed"
    assert_includes result, "opacity-50"
  end

  test "input_class includes error border when errors present" do
    result = input_class(error: true)
    assert_includes result, "border-red-500"
    refute_includes result, "border-slate-600"
  end

  test "input_class uses custom width" do
    result = input_class(width: "w-1/2")
    assert_includes result, "w-1/2"
    refute_includes result, "w-full"
  end

  test "input_class uses w-full by default" do
    result = input_class({})
    assert_includes result, "w-full"
  end

  test "input_class uses default border when no error" do
    result = input_class({})
    assert_includes result, "border-slate-600"
    refute_includes result, "border-red-500"
  end

  test "app_form_with uses AppFormBuilder by default" do
    user = users(:john)
    form_html =
      app_form_with(model: user, url: "/test") { |f| f.text_field(:first_name) }
    assert_includes form_html, "form"
  end

  test "select preserves existing html_options class" do
    html =
      select(:user, :weight_unit, %w[kg lbs], {}, { class: "custom-class" })
    assert_includes html, "custom-class"
    refute_includes html, "bg-slate-800"
  end

  test "select adds input_class when no class provided" do
    html = select(:user, :weight_unit, %w[kg lbs], {}, {})
    assert_includes html, "bg-slate-800"
  end
end
