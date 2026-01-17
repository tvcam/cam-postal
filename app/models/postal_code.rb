class PostalCode < ApplicationRecord
  LOCATION_TYPES = %w[province district commune].freeze
  ALIASES_PATH = Rails.root.join("config/aliases.yml").freeze

  validates :postal_code, presence: true
  validates :name_en, presence: true
  validates :location_type, inclusion: { in: LOCATION_TYPES }

  scope :provinces, -> { where(location_type: "province") }
  scope :districts, -> { where(location_type: "district") }
  scope :communes, -> { where(location_type: "commune") }

  # Load and cache aliases from YAML
  def self.aliases
    @aliases ||= begin
      if File.exist?(ALIASES_PATH)
        YAML.load_file(ALIASES_PATH).transform_keys(&:downcase)
      else
        {}
      end
    end
  end

  # Reload aliases (useful for development)
  def self.reload_aliases!
    @aliases = nil
    aliases
  end

  # Resolve alias to official name, returns original if no alias found
  def self.resolve_alias(query)
    normalized = query.to_s.strip.downcase
    aliases[normalized] || query
  end

  def self.search(query)
    return none if query.blank?

    sanitized = query.to_s.strip
    return none if sanitized.empty?

    # Try alias resolution first
    resolved = resolve_alias(sanitized)
    search_term = resolved != sanitized ? resolved : sanitized

    # Combine FTS and fuzzy results for best matches
    fts_results = fts_search(search_term)

    # Skip fuzzy search for Khmer queries (soundex won't help)
    if khmer_query?(search_term)
      # For Khmer, also do direct LIKE search on name_km
      khmer_like_results = where("name_km LIKE ?", "%#{search_term}%").limit(50)
      fts_ids = fts_results.map(&:id).to_set
      combined = fts_results + khmer_like_results.reject { |r| fts_ids.include?(r.id) }
    else
      fuzzy_results = fuzzy_search(search_term)
      fts_ids = fts_results.map(&:id).to_set
      combined = fts_results + fuzzy_results.reject { |r| fts_ids.include?(r.id) }
    end

    combined.first(50)
  end

  def self.khmer_query?(query)
    # Khmer Unicode range: U+1780 to U+17FF
    query.match?(/[\u1780-\u17FF]/)
  end

  def self.fts_search(query)
    sql = <<-SQL
      SELECT postal_codes.*
      FROM postal_codes
      INNER JOIN postal_codes_fts ON postal_codes.id = postal_codes_fts.rowid
      WHERE postal_codes_fts MATCH ?
      ORDER BY bm25(postal_codes_fts)
      LIMIT 50
    SQL

    fts_query = query.split.map { |term| "#{term}*" }.join(" ")
    find_by_sql([ sql, fts_query ])
  rescue StandardError
    []
  end

  def self.fuzzy_search(query)
    query_terms = query.downcase.split
    query_soundex = query_terms.map { |t| soundex(t) }

    # Get candidates with permissive LIKE - first 2 chars of each term
    like_conditions = query_terms.flat_map do |t|
      patterns = [ "%#{t[0, 2]}%" ]
      # Also try swapping common vowel confusions: ou/uo, o/u
      if t.include?("ou")
        patterns << "%#{t.gsub('ou', 'uo')[0, 3]}%"
      elsif t.include?("uo")
        patterns << "%#{t.gsub('uo', 'ou')[0, 3]}%"
      end
      patterns
    end

    candidates = where(
      like_conditions.map { "LOWER(name_en) LIKE ?" }.join(" OR "),
      *like_conditions
    ).or(
      where("postal_code LIKE ?", "#{query}%")
    ).limit(300)

    # Score and sort by similarity
    scored = candidates.map do |record|
      score = similarity_score(query, record.name_en, query_soundex)
      [ record, score ]
    end

    scored.select { |_, score| score > 0.3 }
          .sort_by { |_, score| -score }
          .first(50)
          .map(&:first)
  end

  def self.similarity_score(query, target, query_soundex = nil)
    return 0.0 if target.blank?

    query_down = query.downcase
    target_down = target.downcase

    # Exact match
    return 1.0 if target_down.include?(query_down)

    query_terms = query_down.split
    target_terms = target_down.split

    # Check each query term against target terms
    term_scores = query_terms.map do |qt|
      best = target_terms.map { |tt| term_similarity(qt, tt) }.max || 0
      best
    end

    # Soundex bonus
    query_soundex ||= query_terms.map { |t| soundex(t) }
    target_soundex = target_terms.map { |t| soundex(t) }
    soundex_matches = (query_soundex & target_soundex).size
    soundex_bonus = soundex_matches.to_f / [ query_soundex.size, 1 ].max * 0.3

    (term_scores.sum / [ term_scores.size, 1 ].max) + soundex_bonus
  end

  def self.term_similarity(s1, s2)
    return 1.0 if s1 == s2
    return 0.9 if s1.start_with?(s2) || s2.start_with?(s1)

    # Bigram similarity
    bg1 = bigrams(s1)
    bg2 = bigrams(s2)
    return 0.0 if bg1.empty? || bg2.empty?

    intersection = (bg1 & bg2).size
    2.0 * intersection / (bg1.size + bg2.size)
  end

  def self.bigrams(str)
    return [] if str.length < 2
    (0..str.length - 2).map { |i| str[i, 2] }
  end

  def self.soundex(str)
    return "" if str.blank?
    str = str.upcase.gsub(/[^A-Z]/, "")
    return "" if str.empty?

    first = str[0]
    coded = str[1..].tr("AEIOUYHW", "00000000")
                    .tr("BFPV", "1111")
                    .tr("CGJKQSXZ", "22222222")
                    .tr("DT", "33")
                    .tr("L", "4")
                    .tr("MN", "55")
                    .tr("R", "6")
                    .gsub(/(.)\1+/, '\1')
                    .delete("0")

    "#{first}#{coded}"[0, 4].ljust(4, "0")
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

  # Get province code from postal code (first 2 digits + 0000)
  def province_code
    "#{postal_code[0, 2]}0000"
  end

  # Get district code from postal code (first 4 digits + 00)
  def district_code
    "#{postal_code[0, 4]}00"
  end

  # Get parent province record
  def province
    return self if province?
    @province ||= PostalCode.find_by(postal_code: province_code, location_type: "province")
  end

  # Get parent district record
  def district
    return self if district?
    return nil if province?
    @district ||= PostalCode.find_by(postal_code: district_code, location_type: "district")
  end

  # Get formatted parent location string
  def parent_location
    parts = []
    parts << district.name_en if commune? && district
    parts << province.name_en if province && !province?
    parts.join(", ")
  end

  def parent_location_km
    parts = []
    parts << district.name_km if commune? && district&.name_km.present?
    parts << province.name_km if province&.name_km.present? && !province?
    parts.join(", ")
  end
end
