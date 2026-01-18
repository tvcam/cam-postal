class PagesController < ApplicationController
  def privacy
  end

  def terms
  end

  def faq
    track_visit
  end

  def api
  end

  def stats
    # Site stats
    @site_visits = SiteStat.visits
    @site_searches = SiteStat.searches
    @site_copies = SiteStat.copies

    # API usage stats
    @api_requests_total = ApiAccessLog.count
    @api_requests_week = ApiAccessLog.this_week.count
    @api_requests_month = ApiAccessLog.this_month.count

    # Top searches (just terms, no user data)
    @top_searches = SearchLog.group(:query)
                             .order("count_all DESC")
                             .limit(10)
                             .count

    # Database stats
    @postal_codes_count = PostalCode.count
    @aliases_count = PostalCode.aliases.count
  end
end
