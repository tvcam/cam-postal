class TimeCapsule < ApplicationRecord
  MOODS = %w[hopeful nostalgic grateful love peaceful mysterious].freeze
  MAX_MESSAGE_LENGTH = 500
  MIN_MESSAGE_LENGTH = 10

  belongs_to :postal_code
  has_many :capsule_hearts, dependent: :destroy

  validates :message, presence: true,
                      length: { minimum: MIN_MESSAGE_LENGTH, maximum: MAX_MESSAGE_LENGTH }
  validates :mood, inclusion: { in: MOODS }, allow_blank: true
  validates :ip_hash, presence: true

  scope :visible, -> { where("visible_at <= ?", Time.current).where(approved: true, flagged: false) }
  scope :pending_visibility, -> { where("visible_at > ?", Time.current) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_hearts, -> { order(hearts_count: :desc) }

  before_validation :set_defaults

  def visible?
    visible_at <= Time.current && approved? && !flagged?
  end

  def time_locked?
    visible_at > Time.current
  end

  def days_until_visible
    return 0 unless time_locked?
    ((visible_at - Time.current) / 1.day).ceil
  end

  def age_label
    days = (Time.current - created_at).to_i / 1.day

    case days
    when 0 then "today"
    when 1 then "yesterday"
    when 2..6 then "#{days} days ago"
    when 7..13 then "1 week ago"
    when 14..29 then "#{days / 7} weeks ago"
    when 30..59 then "1 month ago"
    when 60..364 then "#{days / 30} months ago"
    when 365..729 then "1 year ago"
    else "#{days / 365} years ago"
    end
  end

  def mood_emoji
    case mood
    when "hopeful" then "&#x1F49B;"
    when "nostalgic" then "&#x1F499;"
    when "grateful" then "&#x1F49A;"
    when "love" then "&#x2764;&#xFE0F;"
    when "peaceful" then "&#x1F90D;"
    when "mysterious" then "&#x1F49C;"
    else "&#x1F49B;"
    end
  end

  def hearted_by?(ip_address)
    ip_hash = self.class.hash_ip(ip_address)
    capsule_hearts.exists?(ip_hash: ip_hash)
  end

  def add_heart!(ip_address)
    ip_hash = self.class.hash_ip(ip_address)
    return false if capsule_hearts.exists?(ip_hash: ip_hash)

    capsule_hearts.create!(ip_hash: ip_hash)
    reload
    true
  rescue ActiveRecord::RecordNotUnique
    false
  end

  def remove_heart!(ip_address)
    ip_hash = self.class.hash_ip(ip_address)
    heart = capsule_hearts.find_by(ip_hash: ip_hash)
    return false unless heart

    heart.destroy!
    reload
    true
  end

  def self.hash_ip(ip_address)
    Digest::SHA256.hexdigest("#{ip_address}-capsule-salt-2024")[0, 16]
  end

  def self.can_create?(ip_address)
    ip_hash = hash_ip(ip_address)
    !where(ip_hash: ip_hash)
      .where("created_at > ?", 24.hours.ago)
      .exists?
  end

  private

  def set_defaults
    self.mood ||= "hopeful"
    self.visible_at ||= Time.current
    self.ip_hash = self.class.hash_ip(ip_hash) if ip_hash.present? && ip_hash.length > 16
  end
end
