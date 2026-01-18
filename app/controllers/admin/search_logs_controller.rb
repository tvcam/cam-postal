module Admin
  class SearchLogsController < BaseController
    def index
      @period = params[:period] || "week"
      @search_logs = filtered_logs.recent.limit(100)
      @top_queries = SearchLog.top_queries(limit: 20, since: period_start)
      @total_searches = filtered_logs.count
      @unique_queries = filtered_logs.distinct.count(:query)
    end

    private

    def filtered_logs
      case @period
      when "today" then SearchLog.today
      when "week" then SearchLog.this_week
      when "month" then SearchLog.this_month
      else SearchLog.all
      end
    end

    def period_start
      case @period
      when "today" then Time.current.beginning_of_day
      when "week" then 1.week.ago
      when "month" then 1.month.ago
      else 1.year.ago
      end
    end
  end
end
