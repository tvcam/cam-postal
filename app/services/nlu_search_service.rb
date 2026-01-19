require "net/http"
require "json"

class NluSearchService
  API_URL = "https://api.anthropic.com/v1/messages"
  MODEL = "claude-3-haiku-20240307"
  TIMEOUT = 3

  SYSTEM_PROMPT = <<~PROMPT.freeze
    You are a postal code search assistant for Cambodia. Parse user queries and extract search intent.

    Cambodia has 25 provinces. Each province has districts (khan/sruk), and each district has communes (sangkat/khum).
    Postal codes are 6 digits: first 2 = province, next 2 = district, last 2 = commune.

    Return JSON with these fields:
    - intent: "search_location" | "list_by_parent" | "search_landmark" | "search_nearby"
    - location_name: extracted location name (if any)
    - location_type: "province" | "district" | "commune" | null
    - parent_name: parent location name for "list_by_parent" intent
    - landmark: landmark name for "search_landmark" intent
    - confidence: 0.0 to 1.0

    Examples:
    "postal code for Siem Reap" -> {"intent":"search_location","location_name":"Siem Reap","location_type":"province","confidence":0.95}
    "communes in Phnom Penh" -> {"intent":"list_by_parent","parent_name":"Phnom Penh","location_type":"commune","confidence":0.9}
    "near Angkor Wat" -> {"intent":"search_landmark","landmark":"Angkor Wat","confidence":0.85}
    "districts of Battambang" -> {"intent":"list_by_parent","parent_name":"Battambang","location_type":"district","confidence":0.9}

    Only output valid JSON, nothing else.
  PROMPT

  class << self
    def parse(query)
      new.parse(query)
    end

    def api_key
      Rails.application.credentials.dig(:anthropic, :api_key)
    end

    def enabled?
      api_key.present?
    end
  end

  def parse(query)
    return nil unless self.class.enabled?

    # Check cache first
    cached = NluCache.lookup(query)
    return cached if cached

    # Call Claude API
    intent = call_api(query)
    return nil unless intent

    # Cache if high confidence
    NluCache.store(query, intent)

    intent
  rescue StandardError => e
    Rails.logger.error("[NLU] Error parsing query: #{e.message}")
    nil
  end

  private

  def call_api(query)
    uri = URI(API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = TIMEOUT
    http.read_timeout = TIMEOUT

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["x-api-key"] = self.class.api_key
    request["anthropic-version"] = "2023-06-01"

    request.body = {
      model: MODEL,
      max_tokens: 150,
      system: SYSTEM_PROMPT,
      messages: [
        { role: "user", content: "Parse this Cambodia postal code search query: #{query}" }
      ]
    }.to_json

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.warn("[NLU] API error: #{response.code} - #{response.body}")
      return nil
    end

    result = JSON.parse(response.body)
    content = result.dig("content", 0, "text")
    return nil unless content

    # Parse the JSON response from Claude
    intent = JSON.parse(content).deep_symbolize_keys
    Rails.logger.info("[NLU] Parsed intent: #{intent}")
    intent
  rescue JSON::ParserError => e
    Rails.logger.warn("[NLU] Failed to parse response: #{e.message}")
    nil
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    Rails.logger.warn("[NLU] API timeout: #{e.message}")
    nil
  end
end
