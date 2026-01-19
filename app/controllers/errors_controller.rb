class ErrorsController < ApplicationController
  skip_before_action :verify_authenticity_token

  layout "error"

  def not_found
    respond_to_error(404, "not_found")
  end

  def unprocessable
    respond_to_error(422, "unprocessable")
  end

  def internal_error
    respond_to_error(500, "internal_error")
  end

  def bad_request
    respond_to_error(400, "bad_request")
  end

  private

  def respond_to_error(status, template)
    respond_to do |format|
      format.html { render template, status: status }
      format.json { render json: { error: t("errors.#{template}.title"), status: status }, status: status }
      format.turbo_stream { render turbo_stream: turbo_stream.replace("search-results", partial: "errors/inline", locals: { message: t("errors.#{template}.message") }) }
      format.any { render plain: t("errors.#{template}.title"), status: status }
    end
  end
end
