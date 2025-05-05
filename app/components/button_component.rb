# frozen_string_literal: true

class ButtonComponent < ViewComponent::Base
  STYLES = {
    primary: "bg-blue-500 hover:bg-blue-400 text-white hover:text-white",
    success: "bg-green-500 hover:bg-green-400 text-white hover:text-white",
    danger: "bg-red-500 hover:bg-red-400 text-white hover:text-white",
    warning: "bg-yellow-500 hover:bg-yellow-400 text-white hover:text-white",
    default: "bg-gray-500 hover:bg-gray-400",
    outlined: "bg-white hover:bg-gray-100",
    link: "text-blue-500 hover:text-blue-400",
    link_danger: "text-red-500 hover:text-red-400",
  }.freeze

  SIZE = { default: "px-8 py-2", lg: "!text-base py-3 px-6" }.freeze

  def initialize(
    style: "default",
    size: "default",
    type: "button",
    text: "",
    route: nil,
    data: {},
    **options
  )
    @style = style
    @size = size
    @type = type
    @text = text
    @route = route
    @data = data
    @options = options
  end

  def classes
    common_classes =
      "leading-none cursor-pointer disabled:opacity-75 border-gray-650 block text-center whitespace-nowrap select-none focus:border-gray focus:outline-none focus:ring border leading-normal hover:no-underline rounded" unless inline?

    specific_classes = STYLES[@style.to_sym]
    size = SIZE[@size.to_sym] unless inline?

    "#{common_classes} #{specific_classes} #{size}"
  end

  def inline?
    %w[none link link_danger].include?(@style)
  end
end

