# frozen_string_literal: true

class SettingsMenuComponent < ViewComponent::Base
  include ApplicationHelper
  
  def initialize(current_page:)
    @current_page = current_page
  end

  def menu_items
    [
      { key: :profile, path: settings_profile_path, icon: "user" },
      { key: :garmin, path: settings_garmin_path, icon: "activity" },
      { key: :logs, path: settings_logs_path, icon: "logs" }
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
