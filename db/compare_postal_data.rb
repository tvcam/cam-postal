#!/usr/bin/env ruby
# Script to compare old_postal.json and postal_codes.csv
# Compares by English name and postal code

require 'json'
require 'csv'

# Province ID to postal code prefix mapping
PROVINCE_CODES = {
  12 => "12", 1 => "01", 2 => "02", 3 => "03", 4 => "04",
  5 => "05", 6 => "06", 7 => "07", 8 => "08", 9 => "09",
  10 => "10", 11 => "11", 13 => "13", 14 => "14", 15 => "15",
  16 => "16", 17 => "17", 18 => "18", 19 => "19", 20 => "20",
  21 => "21", 22 => "22", 23 => "23", 24 => "24", 25 => "25"
}

puts "=" * 60
puts "POSTAL DATA COMPARISON: old_postal.json vs postal_codes.csv"
puts "=" * 60
puts

# Parse old_postal.json
old_data = JSON.parse(File.read('db/old_postal.json'))
old_records = {}

old_data.each do |province|
  province_id = province['id']
  province_prefix = PROVINCE_CODES[province_id]
  next unless province_prefix

  province_code = "#{province_prefix}0000"
  old_records[province_code] = { km: province['name'], en: nil, type: 'province' }

  province['districts']&.each do |district|
    if district['no'] =~ /\d+\.(\d+)/
      district_num = $1.to_i
      district_code = "#{province_prefix}%02d00" % district_num
      old_records[district_code] = {
        km: district['location_kh'],
        en: district['location_en'],
        type: 'district'
      }

      district['codes']&.each do |commune|
        old_records[commune['code']] = {
          km: commune['km'],
          en: commune['en'],
          type: 'commune'
        }
      end
    end
  end
end

# Parse postal_codes.csv
csv_data = CSV.read('db/postal_codes.csv', headers: true)
csv_records = {}
csv_data.each do |row|
  csv_records[row['postal_code']] = {
    km: row['name_km'],
    en: row['name_en'],
    type: row['type']
  }
end

# Comparison stats
only_in_old = []
only_in_csv = []
different_en_names = []

# Find codes only in old_postal.json
old_records.each do |code, record|
  unless csv_records.key?(code)
    only_in_old << { code: code, km: record[:km], en: record[:en], type: record[:type] }
  end
end

# Find codes only in CSV
csv_records.each do |code, record|
  unless old_records.key?(code)
    only_in_csv << { code: code, km: record[:km], en: record[:en], type: record[:type] }
  end
end

# Find different English names
old_records.each do |code, old_rec|
  if csv_records.key?(code)
    csv_rec = csv_records[code]
    old_en = old_rec[:en]&.strip&.downcase
    csv_en = csv_rec[:en]&.strip&.downcase
    if old_en && csv_en && old_en != csv_en
      different_en_names << {
        code: code,
        old_en: old_rec[:en],
        csv_en: csv_rec[:en],
        type: old_rec[:type]
      }
    end
  end
end

# Output results
puts "SUMMARY"
puts "-" * 60
puts "old_postal.json total records: #{old_records.size}"
puts "postal_codes.csv total records: #{csv_records.size}"
puts
puts "Only in old_postal.json: #{only_in_old.size}"
puts "Only in postal_codes.csv: #{only_in_csv.size}"
puts "Different English names: #{different_en_names.size}"
puts

if only_in_old.any?
  puts "\n" + "=" * 60
  puts "CODES ONLY IN old_postal.json (#{only_in_old.size}):"
  puts "=" * 60
  only_in_old.sort_by { |r| r[:code] }.each do |rec|
    puts "  #{rec[:code]} | #{rec[:type].ljust(8)} | #{rec[:en] || '(no EN)'} | #{rec[:km]}"
  end
end

if only_in_csv.any?
  puts "\n" + "=" * 60
  puts "CODES ONLY IN postal_codes.csv (#{only_in_csv.size}):"
  puts "=" * 60
  only_in_csv.sort_by { |r| r[:code] }.each do |rec|
    puts "  #{rec[:code]} | #{rec[:type].to_s.ljust(8)} | #{rec[:en] || '(no EN)'}"
  end
end

if different_en_names.any?
  puts "\n" + "=" * 60
  puts "DIFFERENT ENGLISH NAMES (#{different_en_names.size}):"
  puts "=" * 60
  different_en_names.sort_by { |r| r[:code] }.first(50).each do |rec|
    puts "  #{rec[:code]} | #{rec[:type].ljust(8)}"
    puts "    OLD: #{rec[:old_en]}"
    puts "    CSV: #{rec[:csv_en]}"
    puts
  end
  if different_en_names.size > 50
    puts "  ... and #{different_en_names.size - 50} more differences"
  end
end

# Type breakdown
puts "\n" + "=" * 60
puts "BREAKDOWN BY TYPE"
puts "=" * 60

[ 'province', 'district', 'commune' ].each do |type|
  old_count = old_records.count { |_, r| r[:type] == type }
  csv_count = csv_records.count { |_, r| r[:type] == type }
  puts "#{type.capitalize.ljust(10)}: old_postal=#{old_count.to_s.ljust(5)} csv=#{csv_count}"
end
