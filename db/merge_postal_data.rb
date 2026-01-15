#!/usr/bin/env ruby
# Script to merge old_postal.json data into postal_codes.csv
# Priority: NEW CSV data
# Strategy:
# 1. Match by postal code only if English names also match
# 2. Match by exact English name
# 3. Match by similar English name (>80% similarity)
# 4. Add missing postal codes from old data

require 'json'
require 'csv'

PROVINCE_CODES = {
  12 => "12", 1 => "01", 2 => "02", 3 => "03", 4 => "04",
  5 => "05", 6 => "06", 7 => "07", 8 => "08", 9 => "09",
  10 => "10", 11 => "11", 13 => "13", 14 => "14", 15 => "15",
  16 => "16", 17 => "17", 18 => "18", 19 => "19", 20 => "20",
  21 => "21", 22 => "22", 23 => "23", 24 => "24", 25 => "25",
}

# Province Khmer names by postal code
PROVINCE_KM = {
  "010000" => "ខេត្តបន្ទាយមានជ័យ",
  "020000" => "ខេត្តបាត់ដំបង",
  "030000" => "ខេត្តកំពង់ចាម",
  "040000" => "ខេត្តកំពង់ឆ្នាំង",
  "050000" => "ខេត្តកំពង់ស្ពឺ",
  "060000" => "ខេត្តកំពង់ធំ",
  "070000" => "ខេត្តកំពត",
  "080000" => "ខេត្តកណ្តាល",
  "090000" => "ខេត្តកោះកុង",
  "100000" => "ខេត្តក្រចេះ",
  "110000" => "ខេត្តមណ្ឌលគិរី",
  "120000" => "រាជធានីភ្នំពេញ",
  "130000" => "ខេត្តព្រះវិហារ",
  "140000" => "ខេត្តព្រៃវែង",
  "150000" => "ខេត្តពោធិ៍សាត់",
  "160000" => "ខេត្តរតនគិរី",
  "170000" => "ខេត្តសៀមរាប",
  "180000" => "ខេត្តព្រះសីហនុ",
  "190000" => "ខេត្តស្ទឹងត្រែង",
  "200000" => "ខេត្តស្វាយរៀង",
  "210000" => "ខេត្តតាកែវ",
  "220000" => "ខេត្តឧត្តរមានជ័យ",
  "230000" => "ខេត្តកែប",
  "240000" => "ខេត្តប៉ៃលិន",
  "250000" => "ខេត្តត្បូងឃ្មុំ",
}

# Levenshtein distance
def levenshtein(s1, s2)
  return s2.length if s1.empty?
  return s1.length if s2.empty?

  m = s1.length
  n = s2.length
  d = Array.new(m + 1) { Array.new(n + 1, 0) }

  (0..m).each { |i| d[i][0] = i }
  (0..n).each { |j| d[0][j] = j }

  (1..m).each do |i|
    (1..n).each do |j|
      cost = s1[i - 1] == s2[j - 1] ? 0 : 1
      d[i][j] = [d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + cost].min
    end
  end
  d[m][n]
end

def similarity(s1, s2)
  return 0.0 if s1.nil? || s2.nil? || s1.empty? || s2.empty?
  max_len = [s1.length, s2.length].max
  1.0 - (levenshtein(s1, s2).to_f / max_len)
end

def normalize_en(name)
  return nil if name.nil? || name.strip.empty?
  name.strip.downcase
    .gsub(/\s+/, ' ')
    .gsub(/\bti\s+(muoy|pir|bei)\b/, 'ti \1')  # Normalize ti muoy/pir/bei
    .gsub(/\b(i|1|muoy)\b/, '1')                # Normalize numerals
    .gsub(/\b(ii|2|pir)\b/, '2')
    .gsub(/\b(iii|3|bei)\b/, '3')
end

SIMILARITY_THRESHOLD = 0.65

# Read old_postal.json
old_data = JSON.parse(File.read('db/old_postal.json'))

# Build mappings
old_by_code = {}
old_by_name = {}  # normalized_english => {km:, en_original:}

old_data.each do |province|
  province_id = province['id']
  province_prefix = PROVINCE_CODES[province_id]
  next unless province_prefix

  province_code = "#{province_prefix}0000"
  old_by_code[province_code] = {
    km: province['name'],
    en: nil,
    type: 'province',
    province_code: province_code,
    district_code: nil
  }

  province['districts']&.each do |district|
    if district['no'] =~ /\d+\.(\d+)/
      district_num = $1.to_i
      district_code = "#{province_prefix}%02d00" % district_num

      old_by_code[district_code] = {
        km: district['location_kh'],
        en: district['location_en'],
        type: 'district',
        province_code: province_code,
        district_code: district_code
      }

      en_key = normalize_en(district['location_en'])
      old_by_name[en_key] = { km: district['location_kh'], en: district['location_en'] } if en_key

      district['codes']&.each do |commune|
        old_by_code[commune['code']] = {
          km: commune['km'],
          en: commune['en'],
          type: 'commune',
          province_code: province_code,
          district_code: district_code
        }

        en_key = normalize_en(commune['en'])
        old_by_name[en_key] = { km: commune['km'], en: commune['en'] } if en_key
      end
    end
  end
end

puts "Loaded #{old_by_code.size} records by code"
puts "Loaded #{old_by_name.size} records by English name"

# Find best similar match
def find_similar_match(csv_en, old_by_name, threshold)
  csv_normalized = normalize_en(csv_en)
  return nil unless csv_normalized

  best_match = nil
  best_score = 0

  old_by_name.each do |old_normalized, data|
    score = similarity(csv_normalized, old_normalized)
    if score > best_score && score >= threshold
      best_score = score
      best_match = { km: data[:km], en: data[:en], score: score }
    end
  end

  best_match
end

# Read current CSV
csv_data = CSV.read('db/postal_codes.csv', headers: true)
existing_codes = csv_data.map { |row| row['postal_code'] }.to_set

# Track operations
merged_by_code = 0
merged_exact = 0
merged_similar = 0
still_missing = 0
added_count = 0

new_csv_data = []

csv_data.each do |row|
  postal_code = row['postal_code']
  csv_name_km = row['name_km']
  csv_name_en = row['name_en']
  old_record = old_by_code[postal_code]

  if csv_name_km.nil? || csv_name_km.strip.empty?
    matched = false

    # Strategy 0: Province mapping (direct)
    if row['type'] == 'province' && PROVINCE_KM[postal_code]
      row['name_km'] = PROVINCE_KM[postal_code]
      merged_by_code += 1
      puts "MERGED (province): #{postal_code} | #{csv_name_en} => #{PROVINCE_KM[postal_code]}"
      matched = true
    end

    # Strategy 1: Match by postal code if EN names match
    if old_record&.dig(:km)
      old_en = normalize_en(old_record[:en])
      csv_en = normalize_en(csv_name_en)

      if old_en && csv_en && old_en == csv_en
        row['name_km'] = old_record[:km]
        merged_by_code += 1
        puts "MERGED (code+EN): #{postal_code} | #{csv_name_en}"
        matched = true
      end
    end

    # Strategy 2: Exact match by English name
    unless matched
      csv_en_key = normalize_en(csv_name_en)
      if csv_en_key && old_by_name[csv_en_key]
        row['name_km'] = old_by_name[csv_en_key][:km]
        merged_exact += 1
        puts "MERGED (exact EN): #{postal_code} | #{csv_name_en} => #{old_by_name[csv_en_key][:km]}"
        matched = true
      end
    end

    # Strategy 3: Similar match by English name
    unless matched
      similar = find_similar_match(csv_name_en, old_by_name, SIMILARITY_THRESHOLD)
      if similar
        row['name_km'] = similar[:km]
        merged_similar += 1
        puts "MERGED (similar #{(similar[:score] * 100).round}%): #{postal_code} | #{csv_name_en} <=> #{similar[:en]} => #{similar[:km]}"
        matched = true
      end
    end

    unless matched
      still_missing += 1
      # Show best match even if below threshold
      similar = find_similar_match(csv_name_en, old_by_name, 0.0)
      if similar
        puts "NO MATCH: #{postal_code} | #{csv_name_en}"
        puts "   best: #{similar[:en]} (#{(similar[:score] * 100).round}%)"
      else
        puts "NO MATCH: #{postal_code} | #{csv_name_en} => NO DATA IN OLD"
      end
    end
  end

  new_csv_data << row.to_h
end

# Add missing postal codes from old data
old_by_code.each do |code, record|
  unless existing_codes.include?(code)
    if record[:en]
      new_csv_data << {
        'postal_code' => code,
        'name_km' => record[:km],
        'name_en' => record[:en],
        'type' => record[:type],
        'province_code' => record[:province_code],
        'district_code' => record[:district_code]
      }
      added_count += 1
      puts "ADDED: #{code} | #{record[:en]}"
    end
  end
end

# Sort by postal_code
new_csv_data.sort_by! { |row| row['postal_code'] }

# Write updated CSV
CSV.open('db/postal_codes.csv', 'w') do |csv|
  csv << ['postal_code', 'name_km', 'name_en', 'type', 'province_code', 'district_code']
  new_csv_data.each do |row|
    csv << [row['postal_code'], row['name_km'], row['name_en'], row['type'], row['province_code'], row['district_code']]
  end
end

puts "\n" + "=" * 60
puts "SUMMARY"
puts "=" * 60
puts "Merged by code+EN match:  #{merged_by_code}"
puts "Merged by exact EN name:  #{merged_exact}"
puts "Merged by similar EN:     #{merged_similar}"
puts "Still missing (no match): #{still_missing}"
puts "Added from old:           #{added_count}"
puts "Total records:            #{new_csv_data.size}"
puts "Done!"
