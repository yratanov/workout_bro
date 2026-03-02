# frozen_string_literal: true

class SettingsMenuComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(current_page:)
    @current_page = current_page
  end

  def call
    render MenuComponent.new(
             items: [
               { key: :profile, path: settings_profile_path, icon: "user" },
               { key: :weights, path: settings_weights_path, icon: "dumbbell" },
               { key: :garmin, path: settings_garmin_path, icon: "activity" },
               { key: :imports, path: settings_imports_path, icon: "upload" },
               { key: :exports, path: settings_exports_path, icon: "download" },
               { key: :ai, path: settings_ai_path, icon: "sparkles" }
             ],
             current_page: @current_page,
             translation_namespace: "settings.menu"
           )
  end
end
