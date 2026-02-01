# frozen_string_literal: true

class PaginationComponent < ViewComponent::Base
  def initialize(
    pagination: nil,
    path_proc:,
    current_page: nil,
    total_pages: nil
  )
    @current_page = pagination&.current_page || current_page
    @total_pages = pagination&.total_pages || total_pages
    @path_proc = path_proc
  end

  def render?
    @total_pages > 1
  end

  def page_path(page)
    @path_proc.call(page)
  end

  def show_previous?
    @current_page > 1
  end

  def show_next?
    @current_page < @total_pages
  end

  def page_numbers
    pages = []
    if @total_pages <= 7
      pages = (1..@total_pages).to_a
    else
      pages << 1
      pages << :ellipsis if @current_page > 3

      range_start = [@current_page - 1, 2].max
      range_end = [@current_page + 1, @total_pages - 1].min

      if @current_page <= 3
        range_start = 2
        range_end = [4, @total_pages - 1].min
      elsif @current_page >= @total_pages - 2
        range_start = [@total_pages - 3, 2].max
        range_end = @total_pages - 1
      end

      (range_start..range_end).each { |p| pages << p }

      pages << :ellipsis if @current_page < @total_pages - 2
      pages << @total_pages
    end
    pages.uniq
  end
end
