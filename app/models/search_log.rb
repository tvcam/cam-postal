class SearchLog < ApplicationRecord
  validates :query, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :today, -> { where("created_at >= ?", Time.current.beginning_of_day) }
  scope :this_week, -> { where("created_at >= ?", 1.week.ago) }
  scope :this_month, -> { where("created_at >= ?", 1.month.ago) }

  def self.top_queries(limit: 20, since: 1.week.ago)
    where("created_at >= ?", since)
      .group(:query)
      .order("count_all DESC")
      .limit(limit)
      .count
  end

  def self.log_search(query:, ip_address: nil, user_agent: nil, results_count: 0)
    create(
      query: query.to_s.strip.downcase,
      ip_address: ip_address,
      user_agent: user_agent.to_s.truncate(255),
      results_count: results_count
    )
  end
end
