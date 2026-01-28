module ImportsHelper
  def render_import_status_badge(import)
    badge_config = status_badge_config(import.status)
    content_tag(:span, badge_config[:text], class: badge_config[:classes])
  end

  private

  def status_badge_config(status)
    configs = {
      "pending" => {
        text: I18n.t("settings.imports.show.statuses.pending"),
        classes:
          "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-900/50 text-yellow-300"
      },
      "in_progress" => {
        text: I18n.t("settings.imports.show.statuses.in_progress"),
        classes:
          "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-900/50 text-yellow-300"
      },
      "completed" => {
        text: I18n.t("settings.imports.show.statuses.completed"),
        classes:
          "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-900/50 text-green-300"
      },
      "failed" => {
        text: I18n.t("settings.imports.show.statuses.failed"),
        classes:
          "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-900/50 text-red-300"
      }
    }
    configs[status] || configs["pending"]
  end
end
