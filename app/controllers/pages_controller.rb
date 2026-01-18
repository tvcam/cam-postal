class PagesController < ApplicationController
  def privacy
  end

  def terms
  end

  def faq
    track_visit
  end

  def api
    @api_requests_total = ApiAccessLog.count
    @api_requests_week = ApiAccessLog.this_week.count
    @api_requests_month = ApiAccessLog.this_month.count
  end
end
