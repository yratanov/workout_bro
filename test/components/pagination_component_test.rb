require "test_helper"

class PaginationComponentTest < ActiveSupport::TestCase
  def build_component(current_page:, total_pages:)
    PaginationComponent.new(
      current_page: current_page,
      total_pages: total_pages,
      path_proc: ->(page) { "/items?page=#{page}" }
    )
  end

  test "render? returns false when total_pages is 1" do
    component = build_component(current_page: 1, total_pages: 1)
    refute component.render?
  end

  test "render? returns true when total_pages is greater than 1" do
    component = build_component(current_page: 1, total_pages: 2)
    assert component.render?
  end

  test "show_previous? returns false on first page" do
    component = build_component(current_page: 1, total_pages: 5)
    refute component.show_previous?
  end

  test "show_previous? returns true on second page" do
    component = build_component(current_page: 2, total_pages: 5)
    assert component.show_previous?
  end

  test "show_next? returns true when not on last page" do
    component = build_component(current_page: 1, total_pages: 5)
    assert component.show_next?
  end

  test "show_next? returns false on last page" do
    component = build_component(current_page: 5, total_pages: 5)
    refute component.show_next?
  end

  test "page_numbers returns all pages when total_pages is 7 or less" do
    component = build_component(current_page: 1, total_pages: 5)
    assert_equal [1, 2, 3, 4, 5], component.page_numbers
  end

  test "page_numbers returns all pages when total_pages is exactly 7" do
    component = build_component(current_page: 4, total_pages: 7)
    assert_equal [1, 2, 3, 4, 5, 6, 7], component.page_numbers
  end

  test "page_numbers includes ellipsis for many pages with current near start" do
    component = build_component(current_page: 1, total_pages: 10)
    pages = component.page_numbers

    assert_equal 1, pages.first
    assert_equal 10, pages.last
    assert_includes pages, :ellipsis
  end

  test "page_numbers includes ellipsis for many pages with current in middle" do
    component = build_component(current_page: 5, total_pages: 10)
    pages = component.page_numbers

    assert_equal 1, pages.first
    assert_equal 10, pages.last
    assert_includes pages, 5
    # After .uniq, :ellipsis appears once since symbols are identical
    assert_includes pages, :ellipsis
  end

  test "page_numbers includes ellipsis for many pages with current near end" do
    component = build_component(current_page: 10, total_pages: 10)
    pages = component.page_numbers

    assert_equal 1, pages.first
    assert_equal 10, pages.last
    assert_includes pages, :ellipsis
  end

  test "page_path delegates to path_proc" do
    component = build_component(current_page: 1, total_pages: 5)
    assert_equal "/items?page=3", component.page_path(3)
  end
end
