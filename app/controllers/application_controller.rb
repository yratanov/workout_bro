class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  around_action :switch_locale

  helper_method :current_user

  private

  def switch_locale(&)
    resume_session
    locale = Current.user&.locale || I18n.default_locale
    I18n.with_locale(locale, &)
  end

  def current_user
    @current_user ||= Current.user
  end

  def require_admin
    unless current_user&.admin?
      redirect_to root_path,
                  alert: I18n.t("controllers.application.admin_required")
    end
  end

  def paginate(scope, per_page: 25)
    total_count = scope.count
    total_pages = (total_count.to_f / per_page).ceil
    total_pages = 1 if total_pages.zero?

    current_page = [[params[:page].to_i, 1].max, total_pages].min

    offset = (current_page - 1) * per_page
    records = scope.offset(offset).limit(per_page)

    Pagination.new(records:, current_page:, total_pages:, total_count:)
  end

  Pagination = Data.define(:records, :current_page, :total_pages, :total_count)
end
