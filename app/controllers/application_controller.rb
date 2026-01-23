class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  around_action :switch_locale

  private

  def switch_locale(&)
    resume_session
    locale = Current.user&.locale || I18n.default_locale
    I18n.with_locale(locale, &)
  end

  def current_user
    @current_user ||= Current.user
  end
end
