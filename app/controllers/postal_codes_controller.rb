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

    # Round coordinates to ~100m precision for cache efficiency
    cache_key = "geocode:#{lat.round(3)}:#{lng.round(3)}"

    result = Rails.cache.fetch(cache_key, expires_in: 30.days) do
      fetch_from_nominatim(lat, lng)
    end

    render json: result
  rescue StandardError => e
    Rails.logger.error "Locate error: #{e.class} - #{e.message}"
    render json: { error: "Service temporarily unavailable" }, status: :service_unavailable
  end

  private

  def fetch_from_nominatim(lat, lng)
    require "net/http"
    require "json"

    uri = URI("https://nominatim.openstreetmap.org/reverse")
    uri.query = URI.encode_www_form(lat: lat, lon: lng, format: "json", addressdetails: 1)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 5

    request = Net::HTTP::Get.new(uri)
    request["User-Agent"] = "CambodiaPostalCode/1.0"
    request["Accept-Language"] = "en"

    response = http.request(request)
    data = JSON.parse(response.body)

    if data["address"]
      {
        postal_code: data.dig("address", "postcode"),
        area: data.dig("address", "suburb") || data.dig("address", "village") ||
              data.dig("address", "town") || data.dig("address", "city") ||
              data.dig("address", "county"),
        display_name: data["display_name"]
      }
    else
      { error: "Location not found" }
    end
  rescue StandardError => e
    Rails.logger.error "Nominatim error: #{e.message}"
    { error: "Geocoding service unavailable" }
  end
end
