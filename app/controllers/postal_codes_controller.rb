class PostalCodesController < ApplicationController
  def index
    @query = params[:q].to_s.strip
    @results = @query.present? ? PostalCode.search(@query) : []
  end

  def search
    @query = params[:q].to_s.strip
    @results = @query.present? ? PostalCode.search(@query) : []

    respond_to do |format|
      format.html { render partial: "results", locals: { results: @results, query: @query } }
      format.turbo_stream
    end
  end
end
