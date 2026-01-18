module Admin
  class ApiAccessLogsController < BaseController
    def index
      @logs = ApiAccessLog.recent.limit(100)
      @total_count = ApiAccessLog.count
      @today_count = ApiAccessLog.today.count
      @week_count = ApiAccessLog.this_week.count
      @by_ip = ApiAccessLog.by_ip(limit: 10)
    end
  end
end
