class ApiAccessLog < ApplicationRecord
  scope :recent, -> { order(created_at: :desc) }
  scope :today, -> { where("created_at >= ?", Time.current.beginning_of_day) }
  scope :this_week, -> { where("created_at >= ?", 1.week.ago) }
  scope :this_month, -> { where("created_at >= ?", 1.month.ago) }

  # Domains to exclude from logging (our own app)
  OWN_DOMAINS = %w[cambo-postal.com cam-postal.gotabs.net localhost 127.0.0.1].freeze

  def self.log_access(endpoint:, ip_address:, user_agent:, referer: nil)
    # Skip logging for our own app requests
    return if internal_request?(referer)

    create(
      endpoint: endpoint,
      ip_address: ip_address,
      user_agent: user_agent.to_s.truncate(500)
    )
  end

  def self.internal_request?(referer)
    return false if referer.blank?

    OWN_DOMAINS.any? { |domain| referer.include?(domain) }
  end

  def self.by_ip(limit: 20, since: 1.week.ago)
    where("created_at >= ?", since)
      .group(:ip_address)
      .order("count_all DESC")
      .limit(limit)
      .count
  end
end
