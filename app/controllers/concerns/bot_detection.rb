# Bot detection concern for filtering automated requests from stats
module BotDetection
  extend ActiveSupport::Concern

  private

  # Common bot user agent patterns
  BOT_PATTERNS = [
    /bot/i, /crawler/i, /spider/i, /scraper/i,
    /googlebot/i, /bingbot/i, /yandex/i, /baidu/i,
    /duckduckbot/i, /slurp/i, /facebookexternalhit/i,
    /linkedinbot/i, /twitterbot/i, /whatsapp/i, /telegram/i,
    /applebot/i, /ahrefsbot/i, /semrushbot/i, /mj12bot/i,
    /dotbot/i, /petalbot/i, /bytespider/i,
    /headless/i, /phantom/i, /puppeteer/i, /playwright/i,
    /selenium/i, /webdriver/i,
    /curl/i, /wget/i, /python-requests/i, /python-urllib/i,
    /java\//i, /go-http-client/i, /axios/i, /node-fetch/i,
    /http\.rb/i, /guzzle/i, /okhttp/i,
    /lighthouse/i, /pagespeed/i, /gtmetrix/i,
    /pingdom/i, /uptimerobot/i, /statuscake/i
  ].freeze

  def bot_request?
    user_agent = request.user_agent.to_s
    return true if user_agent.blank?
    return true if BOT_PATTERNS.any? { |pattern| user_agent.match?(pattern) }
    false
  end

  def track_stat(name)
    return if bot_request?
    SiteStat.increment(name)
  end

  def track_visit
    track_stat("visits")
  end

  def track_search
    track_stat("searches")
  end

  def track_copy
    track_stat("copies")
  end
end
