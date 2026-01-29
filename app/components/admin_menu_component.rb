# frozen_string_literal: true

class AdminMenuComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(current_page:)
    @current_page = current_page
  end

  def menu_items
    [
      { key: :users, path: admin_users_path, icon: "user" },
      { key: :logs, path: admin_logs_path, icon: "logs" },
      { key: :invites, path: admin_invites_path, icon: "plus" }
    ]
  end

  def active?(key)
    @current_page == key
  end

  def item_classes(key)
    base = "flex items-center gap-3 px-4 py-3 rounded-lg transition-colors"
    if active?(key)
      "#{base} bg-slate-700 text-white"
    else
      "#{base} text-slate-400 hover:bg-slate-700/50 hover:text-white"
    end
  end
end
