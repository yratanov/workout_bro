# frozen_string_literal: true

class AdminMenuComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(current_page:)
    @current_page = current_page
  end

  def call
    render MenuComponent.new(
             items: [
               { key: :users, path: admin_users_path, icon: "user" },
               { key: :logs, path: admin_logs_path, icon: "logs" },
               { key: :ai_logs, path: admin_ai_logs_path, icon: "sparkles" },
               { key: :invites, path: admin_invites_path, icon: "plus" }
             ],
             current_page: @current_page,
             translation_namespace: "admin.menu"
           )
  end
end
