class NluCache < ApplicationRecord
  validates :query_hash, presence: true, uniqueness: true
  validates :original_query, presence: true
  validates :parsed_intent, presence: true

  class << self
    def lookup(query)
      normalized = normalize_query(query)
      hash = Digest::SHA256.hexdigest(normalized)

      cache = find_by(query_hash: hash)
      return nil unless cache

      cache.increment!(:hit_count)
      cache.parsed_intent.deep_symbolize_keys
    end

    def store(query, intent)
      return if intent[:confidence].to_f < 0.7

      normalized = normalize_query(query)
      hash = Digest::SHA256.hexdigest(normalized)

      find_or_create_by(query_hash: hash) do |cache|
        cache.original_query = query
        cache.parsed_intent = intent
        cache.hit_count = 0
      end
    rescue ActiveRecord::RecordNotUnique
      # Race condition - another request stored it first, that's fine
    end

    def normalize_query(query)
      query.to_s
           .downcase
           .strip
           .gsub(/\s+/, " ")
           .gsub(/[^\p{L}\p{N}\s]/, "")
    end

    def cleanup_stale(days: 30)
      where("updated_at < ?", days.days.ago)
        .where("hit_count < ?", 3)
        .delete_all
    end
  end
end
