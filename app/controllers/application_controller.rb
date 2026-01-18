class ApplicationController < ActionController::Base
  include BotDetection

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # i18n locale handling
  around_action :switch_locale

  private

  def switch_locale(&action)
    locale = params[:locale] || cookies[:locale] || extract_locale_from_accept_language_header || I18n.default_locale
    locale = locale.to_sym
    locale = I18n.default_locale unless I18n.available_locales.include?(locale)
    I18n.with_locale(locale, &action)
  end

  def extract_locale_from_accept_language_header
    return nil unless request.env["HTTP_ACCEPT_LANGUAGE"]

    accepted = request.env["HTTP_ACCEPT_LANGUAGE"].scan(/[a-z]{2}/).first&.to_sym
    I18n.available_locales.include?(accepted) ? accepted : nil
  end

  def default_url_options
    { locale: I18n.locale == I18n.default_locale ? nil : I18n.locale }
  end
end
