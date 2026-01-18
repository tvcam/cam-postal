#!/usr/bin/env ruby
# Merge CSV chunks and update database with Khmer names
# Usage: bin/rails runner scripts/merge_and_import.rb

require "csv"

CSV_DIR = Rails.root.join("db/csv_chunks")
OUTPUT_CSV = Rails.root.join("db/postal_codes_full.csv")

# Collect all data from CSV chunks
all_data = {}

Dir.glob(CSV_DIR.join("page_*.csv")).sort.each do |file|
  puts "Reading #{File.basename(file)}..."

  CSV.foreach(file, headers: true) do |row|
    postal_code = row["postal_code"]&.strip
    next if postal_code.nil? || postal_code.empty?

    # Use postal_code as key, later files override earlier ones
    all_data[postal_code] = {
      postal_code: postal_code,
      name_km: row["name_km"]&.strip,
      name_en: row["name_en"]&.strip,
      type: row["type"]&.strip
    }
  end
end

puts "\nTotal unique postal codes: #{all_data.size}"

# Write merged CSV
puts "\nWriting merged CSV to #{OUTPUT_CSV}..."
CSV.open(OUTPUT_CSV, "w") do |csv|
  csv << [ "postal_code", "name_km", "name_en", "location_type" ]
  all_data.values.sort_by { |d| d[:postal_code] }.each do |data|
    csv << [ data[:postal_code], data[:name_km], data[:name_en], data[:type] ]
  end
end

# Update database
puts "\nUpdating database..."
updated = 0
not_found = 0
already_set = 0

all_data.each do |postal_code, data|
  record = PostalCode.find_by(postal_code: postal_code)

  if record.nil?
    not_found += 1
    next
  end

  if record.name_km.present?
    already_set += 1
    next
  end

  if data[:name_km].present?
    record.update!(name_km: data[:name_km])
    updated += 1
  end
end

puts "\nResults:"
puts "  Updated: #{updated}"
puts "  Already had Khmer name: #{already_set}"
puts "  Not found in DB: #{not_found}"

# Rebuild FTS index
if updated > 0
  puts "\nRebuilding FTS index..."
  ActiveRecord::Base.connection.execute("INSERT INTO postal_codes_fts(postal_codes_fts) VALUES('rebuild')")
  puts "Done!"
end
