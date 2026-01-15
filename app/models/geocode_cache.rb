class GeocodeCache < ApplicationRecord
  def self.lookup(lat, lng)
    # Round to ~100m precision
    rounded_lat = lat.round(3)
    rounded_lng = lng.round(3)

    cached = find_by(lat: rounded_lat, lng: rounded_lng)
    return cached.to_result if cached

    result = fetch_from_nominatim(lat, lng)

    if result[:postal_code] || result[:area]
      create(
        lat: rounded_lat,
        lng: rounded_lng,
        postal_code: result[:postal_code],
        area: result[:area],
        display_name: result[:display_name]
      )
    end

    result
  rescue ActiveRecord::RecordNotUnique
    # Race condition - another request created it first
    find_by(lat: rounded_lat, lng: rounded_lng)&.to_result || { error: "Location not found" }
  end

  def to_result
    {
      postal_code: postal_code,
      area: area,
      display_name: display_name
    }
  end

  private

  def self.fetch_from_nominatim(lat, lng)
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
