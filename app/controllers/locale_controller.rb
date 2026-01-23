class LocaleController < ApplicationController
  skip_around_action :switch_locale

  def switch
    locale = params[:locale]&.to_sym

    if I18n.available_locales.include?(locale)
      cookies.permanent[:locale] = locale.to_s
      session[:locale] = locale.to_s
    end

    redirect_back fallback_location: root_path, allow_other_host: false
  end
end
