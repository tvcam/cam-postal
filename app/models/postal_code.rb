class PostalCode < ApplicationRecord
  LOCATION_TYPES = %w[province district commune].freeze

  validates :postal_code, presence: true
  validates :name_en, presence: true
  validates :location_type, inclusion: { in: LOCATION_TYPES }

  scope :provinces, -> { where(location_type: "province") }
  scope :districts, -> { where(location_type: "district") }
  scope :communes, -> { where(location_type: "commune") }

  def self.search(query)
    return none if query.blank?

    sanitized = query.to_s.strip
    return none if sanitized.empty?

    # Use FTS5 for full-text search with prefix matching
    sql = <<-SQL
      SELECT postal_codes.*
      FROM postal_codes
      INNER JOIN postal_codes_fts ON postal_codes.id = postal_codes_fts.rowid
      WHERE postal_codes_fts MATCH ?
      ORDER BY bm25(postal_codes_fts)
      LIMIT 50
    SQL

    # Add * for prefix matching (fuzzy search)
    fts_query = sanitized.split.map { |term| "#{term}*" }.join(" ")

    find_by_sql([ sql, fts_query ])
  rescue StandardError
    # Fallback to LIKE search if FTS fails
    where("postal_code LIKE :q OR name_en LIKE :q OR name_km LIKE :q",
          q: "%#{sanitized}%").limit(50)
  end

  def province?
    location_type == "province"
  end

  def district?
    location_type == "district"
  end

  def commune?
    location_type == "commune"
  end

  def type_label
    case location_type
    when "province" then "Province"
    when "district" then "District"
    when "commune" then "Commune"
    else location_type&.titleize
    end
  end
end
