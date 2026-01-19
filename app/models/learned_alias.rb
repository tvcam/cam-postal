class LearnedAlias < ApplicationRecord
  # Thresholds for auto-promotion
  MIN_CLICKS = 10
  MIN_CLICK_RATE = 0.6  # 60%
  MIN_UNIQUE_IPS = 5

  validates :search_term, presence: true
  validates :postal_code, presence: true
  validates :search_term, uniqueness: { scope: :postal_code }

  # Association to get location details
  belongs_to :postal_code_record, class_name: "PostalCode", primary_key: "postal_code", foreign_key: "postal_code", optional: true

  scope :promoted, -> { where(promoted: true) }
  scope :pending, -> { where(promoted: false) }

  # Sorting scopes
  scope :order_by_rate, ->(direction = :desc) {
    order(Arel.sql("CASE WHEN search_count = 0 THEN 0 ELSE CAST(click_count AS FLOAT) / search_count END #{direction}"))
  }

  # Class method for average click rate
  def self.average_click_rate
    return 0 if count.zero?
    where("search_count > 0").average("CAST(click_count AS FLOAT) / search_count") || 0
  end

  # Record a search term (called when user searches)
  def self.record_search(term, ip_address: nil)
    return if term.blank? || term.length < 2

    normalized = term.to_s.strip.downcase
    where(search_term: normalized).update_all("search_count = search_count + 1")
  rescue StandardError => e
    Rails.logger.error "LearnedAlias.record_search error: #{e.message}"
  end

  # Record a click (called when user copies/clicks a result)
  def self.record_click(term, postal_code, ip_address: nil)
    return if term.blank? || postal_code.blank?

    normalized = term.to_s.strip.downcase

    record = find_or_initialize_by(search_term: normalized, postal_code: postal_code)
    record.click_count += 1
    record.last_clicked_at = Time.current

    # Track unique IPs (simple increment - not perfect but lightweight)
    # In production, could use a separate table or HyperLogLog
    record.unique_ips += 1 if record.new_record? || should_count_ip?(record, ip_address)

    record.save!
    record.check_promotion!
    record
  rescue ActiveRecord::RecordNotUnique
    # Race condition - retry
    retry
  rescue StandardError => e
    Rails.logger.error "LearnedAlias.record_click error: #{e.message}"
    nil
  end

  # Check if this alias should be promoted
  def check_promotion!
    return if promoted?
    return unless meets_promotion_criteria?

    update!(promoted: true)
    Rails.logger.info "LearnedAlias promoted: '#{search_term}' -> #{postal_code}"
  end

  def meets_promotion_criteria?
    click_count >= MIN_CLICKS &&
      click_rate >= MIN_CLICK_RATE &&
      unique_ips >= MIN_UNIQUE_IPS
  end

  def click_rate
    return 0 if search_count.zero?
    click_count.to_f / search_count
  end

  # Get all promoted aliases as a hash for search
  def self.promoted_aliases
    promoted.pluck(:search_term, :postal_code).to_h
  end

  # Get the location name for a promoted alias
  def self.resolve(term)
    normalized = term.to_s.strip.downcase
    record = promoted.find_by(search_term: normalized)
    return nil unless record

    location = PostalCode.find_by(postal_code: record.postal_code)
    location&.name_en
  end

  private

  # Simple IP tracking - count if last click was > 1 hour ago
  # This prevents same user clicking multiple times from inflating unique_ips
  def self.should_count_ip?(record, ip_address)
    return true if record.last_clicked_at.nil?
    record.last_clicked_at < 1.hour.ago
  end
end
