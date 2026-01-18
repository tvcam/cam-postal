# Rate limiting configuration using Rack::Attack
# Protects the app from abuse while allowing normal usage

class Rack::Attack
  # Use Rails cache for storage
  Rack::Attack.cache.store = Rails.cache

  # Safelist localhost in development
  safelist("localhost") do |req|
    req.ip == "127.0.0.1" || req.ip == "::1"
  end

  # Throttle general requests by IP (120 requests per minute)
  throttle("req/ip", limit: 120, period: 1.minute) do |req|
    req.ip unless req.path.start_with?("/assets")
  end

  # Stricter limit for search API (30 searches per minute per IP)
  throttle("search/ip", limit: 30, period: 1.minute) do |req|
    req.ip if req.path == "/track/search" || req.path == "/search"
  end

  # Stricter limit for copy tracking (60 per minute per IP)
  throttle("copy/ip", limit: 60, period: 1.minute) do |req|
    req.ip if req.path == "/track/copy"
  end

  # Limit data.json requests (10 per hour per IP - it's cached anyway)
  throttle("data/ip", limit: 10, period: 1.hour) do |req|
    req.ip if req.path == "/data.json"
  end

  # Limit locate API (30 per minute per IP)
  throttle("locate/ip", limit: 30, period: 1.minute) do |req|
    req.ip if req.path == "/locate"
  end

  # Block suspicious patterns (common exploit paths)
  blocklist("bad-paths") do |req|
    req.path.match?(/\.(php|asp|aspx|jsp|cgi)$/i) ||
      req.path.include?("wp-admin") ||
      req.path.include?("wp-content") ||
      req.path.include?("xmlrpc") ||
      req.path.include?(".env")
  end

  # Custom response for throttled requests
  self.throttled_responder = lambda do |req|
    [
      429,
      { "Content-Type" => "application/json", "Retry-After" => "60" },
      [{ error: "Rate limit exceeded. Please try again later." }.to_json]
    ]
  end

  # Custom response for blocked requests
  self.blocklisted_responder = lambda do |req|
    [403, { "Content-Type" => "text/plain" }, ["Forbidden"]]
  end
end
