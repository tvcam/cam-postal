class ApplicationController < ActionController::Base
  include BotDetection

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # i18n locale handling
  around_action :switch_locale

  # Error handling
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::RoutingError, with: :render_not_found
  rescue_from ActionController::InvalidAuthenticityToken, with: :render_unprocessable
  rescue_from ActionController::ParameterMissing, with: :render_bad_request

  private
  
  def switch_locale(&action)
    locale = params[:locale] || session[:locale] || cookies[:locale] || extract_locale_from_accept_language_header || I18n.default_locale
    locale = locale.to_s.to_sym
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

  def render_not_found
    respond_to_error(404, "errors/not_found")
  end

  def render_unprocessable
    respond_to_error(422, "errors/unprocessable")
  end

  def render_bad_request
    respond_to_error(400, "errors/bad_request")
  end

  def render_internal_error
    respond_to_error(500, "errors/internal_error")
  end

  def respond_to_error(status, template)
    respond_to do |format|
      format.html { render template, layout: "error", status: status }
      format.json { render json: { error: I18n.t("errors.#{template.split('/').last}.title"), status: status }, status: status }
      format.turbo_stream { render turbo_stream: turbo_stream.replace("search-results", partial: "errors/inline", locals: { message: I18n.t("errors.#{template.split('/').last}.message") }) }
      format.any { render plain: I18n.t("errors.#{template.split('/').last}.title"), status: status }
    end
  end
end
