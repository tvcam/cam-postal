class PostalCodesController < ApplicationController
  def index
    @query = params[:q].to_s.strip
    @results = @query.present? ? PostalCode.search(@query) : []
    SiteStat.increment("visits")
  end

  def search
    @query = params[:q].to_s.strip
    @results = @query.present? ? PostalCode.search(@query) : []

    SiteStat.increment("searches") if @query.present?

    respond_to do |format|
      format.html do
        if turbo_frame_request?
          render layout: false
        else
          render :search_page
        end
      end
      format.turbo_stream
    end
  end

  def track_copy
    SiteStat.increment("copies")
    head :ok
  end

  def locate
    lat = params[:lat].to_f
    lng = params[:lng].to_f

    return render json: { error: "Invalid coordinates" }, status: :bad_request if lat.zero? || lng.zero?

    result = GeocodeCache.lookup(lat, lng)
    render json: result
  rescue StandardError => e
    Rails.logger.error "Locate error: #{e.class} - #{e.message}"
    render json: { error: "Service temporarily unavailable" }, status: :service_unavailable
  end
end
