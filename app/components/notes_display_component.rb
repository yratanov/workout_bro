# frozen_string_literal: true

class NotesDisplayComponent < ViewComponent::Base
  def initialize(notes:, edit_path: nil, empty_text: nil, bg_class: "bg-slate-700/50")
    @notes = notes
    @edit_path = edit_path
    @empty_text = empty_text
    @bg_class = bg_class
  end

  attr_reader :notes, :edit_path, :empty_text, :bg_class

  def render?
    notes.present? || edit_path.present?
  end
end
